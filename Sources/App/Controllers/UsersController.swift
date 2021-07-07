//
//  UsersController.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Foundation
import Vapor
import Fluent
import Mailgun
import Leaf

class UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let usersRoute = routes.grouped(User.pathComponent)
        let tokenProtectedUsersRoute = usersRoute.grouped(UserBearerAuthenticator())
        
        tokenProtectedUsersRoute.get(use: getUser)
        tokenProtectedUsersRoute.get(":userId", use: getUser)
        usersRoute.get("status", use: getUserStatusWithEmail)
        tokenProtectedUsersRoute.get("search", use: searchUsers)
        tokenProtectedUsersRoute.post(":userId", "follow", use: follow)
        tokenProtectedUsersRoute.delete(":userId", "unfollow", use: unfollow)
        tokenProtectedUsersRoute.get(":userId", ":followType", use: getFollows)
        tokenProtectedUsersRoute.delete(use: deleteUser)
        tokenProtectedUsersRoute.delete(":userId", use: deleteUser)
        tokenProtectedUsersRoute.put(use: updateUser)
        tokenProtectedUsersRoute.put(":userId", use: updateUser)
        tokenProtectedUsersRoute.post("profilePhoto", use: uploadProfilePhoto)
        tokenProtectedUsersRoute.delete("profilePhoto", use: deleteProfilePhoto)
    }
    
    // MARK: Get User
    
    func getUser(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = req.userId(loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            return User.find(userId, on: req.db).flatMapThrowing { user in
                guard let user = user else { throw Exception.userDoesNotExist }
                return try user.asPublic()
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    // MARK: Get User Status
    
    func getUserStatusWithEmail(req: Request) throws -> EventLoopFuture<UserStatus> {
        guard let email = req.query[String.self, at: "email"] else {
            throw Exception.missingEmail
        }
        return User.query(on: req.db).filter(\.$email == email).first().flatMapThrowing { existingUser in
            guard existingUser != nil else {
                return UserStatus(email: email, exists: false)
            }
            return UserStatus(email: email, exists: true)
        }
    }
    
    // MARK: Search Users
    
    func searchUsers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            return User.query(on: req.db)
                .filter(\.$id == loggedInUser.id ?? UUID())
                .with(\.$followers)
                .with(\.$following).first().flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                let query = req.query[String.self, at: "query"] ?? ""
                var futureUsers = User.query(on: req.db)
                    .group(.or) { group in
                    group.filter(\.$firstName, .caseInsensitiveContains, "%\(query)%")
                        .filter(\.$lastName, .caseInsensitiveContains, "%\(query)%")
                        .filter(\.$username, .caseInsensitiveContains, "%\(query)%")
                        .filter(\.$email, .caseInsensitiveContains, "%\(query)%")
                }
                if let excludeMe = req.query[String.self, at: "excludeMe"], excludeMe == "yes" {
                    futureUsers = futureUsers.filter(\.$id != user.id ?? UUID())
                }
                futureUsers = self.addAdminFilter(to: futureUsers, req: req)
                futureUsers = self.addFollowsFilter(to: futureUsers, user: user, req: req)
                let (start, end) = req.searchRange
                return futureUsers.range(start..<end).all().flatMapThrowing { users in
                    return try users.compactMap { try $0.asPublic() }
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func addAdminFilter(to queryBuilder: QueryBuilder<User>,
                                req: Request) -> QueryBuilder<User> {
        guard let isAdminString = req.query[String.self, at: "isAdmin"],
              ["yes", "no"].contains(isAdminString) else { return queryBuilder }
        return queryBuilder.filter(\.$isAdmin == (isAdminString == "yes"))
    }
    
    private func addFollowsFilter(to queryBuilder: QueryBuilder<User>,
                                  user: User,
                                  req: Request) -> QueryBuilder<User> {
        var newQueryBuilder = queryBuilder
        newQueryBuilder = filterFollows("isFollower", user, queryBuilder: newQueryBuilder, req: req)
        newQueryBuilder = filterFollows("isFollowing", user, queryBuilder: newQueryBuilder, req: req)
        return newQueryBuilder
    }
    
    private func filterFollows(_ queryString: String,
                               _ user: User,
                               queryBuilder: QueryBuilder<User>,
                               req: Request) -> QueryBuilder<User> {
        let follows = queryString == "isFollower" ? user.followers : user.following
        let userIds = follows.compactMap { $0.id }
        guard let isFollow = req.query[String.self, at: queryString], ["yes", "no"].contains(isFollow) else {
            return queryBuilder
        }
        return filterUserIds(userIds, include: isFollow == "yes", queryBuilder: queryBuilder)
    }
    
    private func filterUserIds(_ userIds: [UUID],
                               include: Bool,
                               queryBuilder: QueryBuilder<User>) -> QueryBuilder<User> {
        return include ? queryBuilder.filter(\.$id ~~ userIds) : queryBuilder.filter(\.$id !~ userIds)
    }
    
    // MARK: Set Following Status
    
    func follow(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try setFollowingStatus(req: req, to: true)
    }
    
    func unfollow(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try setFollowingStatus(req: req, to: false)
    }
    
    func setFollowingStatus(req: Request, to newFollowingStatus: Bool) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = loggedInUser.id,
                  let otherUserId = req.parameters.get("userId") else {
                return req.fail(Exception.missingUserId)
            }
            return User.find(userId, on: req.db).flatMap { user in
                return User.find(UUID(otherUserId), on: req.db).flatMap { otherUser in
                    guard let user = user, let otherUser = otherUser else {
                        return req.fail(Exception.userDoesNotExist)
                    }
                    // Check if user is already following other user
                    return FollowingFollower.query(on: req.db)
                        .filter(\.$follower.$id == user.id ?? UUID())
                        .filter(\.$following.$id == otherUser.id ?? UUID())
                        .first()
                        .flatMap { existingConnection in
                        if newFollowingStatus == true {
                            guard existingConnection == nil else {
                                return req.success(HTTPStatus.ok)
                            }
                            guard user.id != otherUser.id else {
                                return req.fail(Exception.cannotFollowSelf)
                            }
                            return user.$following.attach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
                        } else {
                            return user.$following.detach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
                        }
                    }
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    // MARK: Get Follows
    
    func getFollows(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = req.userId(loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            guard let followType = req.parameters.get("followType") else {
                return req.fail(Exception.missingFollowType)
            }
            let _ = try AuthUtility.getAuthorizedUser(req: req)
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                if followType == "followers" {
                    return self.followers(of: user, req: req)
                } else if followType == "following" {
                    return self.following(of: user, req: req)
                } else {
                    return req.fail(Exception.invalidFollowType)
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func followers(of user: User, req: Request) -> EventLoopFuture<[User.Public]> {
        return user.$followers.query(on: req.db).all().flatMapThrowing { users in
            return try users.compactMap { try $0.asPublic() }
        }
    }
    
    func following(of user: User, req: Request) -> EventLoopFuture<[User.Public]> {
        return user.$following.query(on: req.db).all().flatMapThrowing { users in
            return try users.compactMap { try $0.asPublic() }
        }
    }
    
    // MARK: Delete User
    
    func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = req.userId(loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: userId != loggedInUser.id)
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                return self.delete(user: user, req: req)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func delete(user: User, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let userId = user.id else {
            return req.fail(Exception.missingUserId)
        }
        // Delete following/follower records for this user
        return FollowingFollower.query(on: req.db).group(.or) { group in
            group.filter(\.$follower.$id == userId).filter(\.$following.$id == userId)
        }.delete().flatMap {
            // Delete all posts for this user
            return Post.query(on: req.db).filter(\.$user.$id == userId).delete().flatMap {
                // Delete all tokens for this user
                return Token.query(on: req.db).filter(\.$user.$id == userId).delete().flatMap {
                    // Delete user
                    let profilePhotoInfo = ProfilePhotoInfo(req, userId, existingUrl: user.profilePhotoUrl)
                    if let existingFilePath = profilePhotoInfo.existingFilePath {
                        try? FileManager.default.removeItem(atPath: existingFilePath)
                    }
                    return user.delete(on: req.db).transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
    // MARK: Update User
    
    func updateUser(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userUpdate = try? req.content.decode(UserUpdate.self) else {
                return req.fail(Exception.missingUserUpdate)
            }
            guard let userId = req.userId(loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                if let firstName = userUpdate.firstName { user.firstName = firstName }
                if let lastName = userUpdate.lastName { user.lastName = lastName }
                if let username = userUpdate.username { user.username = username }
                if loggedInUser.isAdmin == true {
                    if let isAdmin = userUpdate.isAdmin { user.isAdmin = isAdmin }
                }
                if let email = userUpdate.email {
                    return User.query(on: req.db).filter(\.$email == email).first().flatMap { existingUser in
                        if existingUser != nil {
                            return req.fail(Exception.userAlreadyExists)
                        }
                        user.email = email
                        user.isEmailVerified = Settings().requireEmailVerification ? false : true
                        guard let publicUser = try? user.asPublic() else {
                            return req.fail(Exception.unknown)
                        }
                        return user.save(on: req.db).transform(to: publicUser)
                    }
                }
                guard let publicUser = try? user.asPublic() else {
                    return req.fail(Exception.unknown)
                }
                return user.save(on: req.db).transform(to: publicUser)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    // MARK: Upload Profile Photo
    
    func uploadProfilePhoto(req: Request) throws -> EventLoopFuture<ProfilePhotoUploadResponse> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id else {
                return req.fail(Exception.missingUserId)
            }
            let photo = try req.content.decode(ProfilePhoto.self)
            guard let ext = photo.file.extension?.lowercased(),
                  Settings().allowedImageTypes.contains(ext) else {
                return req.fail(Exception.invalidImageType)
            }
            
            let profilePhotoInfo = ProfilePhotoInfo(req, userId, ext: ext)
            try FileManager.default.createDirectory(atPath: profilePhotoInfo.directoryPath,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        
            return saveProfilePhotoUrl(req: req,
                                       userId: userId,
                                       url: profilePhotoInfo.url).flatMap { exception in
                if let exception = exception {
                    return req.fail(exception)
                }
                return req.application.fileio.openFile(path: profilePhotoInfo.filePath,
                                                       mode: .write,
                                                       flags: .allowFileCreation(posixMode: S_IRWXU | S_IRWXG | S_IRWXO),
                                                       eventLoop: req.eventLoop).flatMap { handle in
                    req.application.fileio.write(fileHandle: handle,
                                                 buffer: photo.file.data,
                                                 eventLoop: req.eventLoop).flatMapThrowing { _ in
                        try handle.close()
                        return ProfilePhotoUploadResponse(url: profilePhotoInfo.url)
                    }
                }
            }
            
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    // MARK: Delete Profile Photo
    
    func deleteProfilePhoto(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id else {
                return req.fail(Exception.missingUserId)
            }
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                let profilePhotoInfo = ProfilePhotoInfo(req, userId, existingUrl: user.profilePhotoUrl)
                if let existingFilePath = profilePhotoInfo.existingFilePath {
                    try? FileManager.default.removeItem(atPath: existingFilePath)
                }
                user.profilePhotoUrl = nil
                return user.save(on: req.db).transform(to: HTTPStatus.ok)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func saveProfilePhotoUrl(req: Request,
                             userId: UUID,
                             url: String) -> EventLoopFuture<Exception?> {
        return User.find(userId, on: req.db).flatMap { user in
            guard let user = user else {
                return req.success(Exception.userDoesNotExist)
            }
            user.profilePhotoUrl = url
            return user.save(on: req.db).transform(to: nil)
        }
    }
}
