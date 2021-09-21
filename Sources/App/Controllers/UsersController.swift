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
import SotoS3

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
        tokenProtectedUsersRoute.get(":userId", "followStatus", use: getFollowStatus)
        tokenProtectedUsersRoute.delete(use: deleteUser)
        tokenProtectedUsersRoute.delete(":userId", use: deleteUser)
        tokenProtectedUsersRoute.put(use: updateUser)
        tokenProtectedUsersRoute.put(":userId", use: updateUser)
        tokenProtectedUsersRoute.post("profilePhoto", use: uploadProfilePhoto)
        tokenProtectedUsersRoute.delete("profilePhoto", use: deleteProfilePhoto)
    }
    
    /// Get User
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///
    /// - Returns: User.Public
    ///
    func getUser(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = req.userId(defaultToIdOf: loggedInUser) else {
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
    
    /// Get User Status
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - missingEmail - You must provide an email.
    ///
    /// - Returns: UserStatus
    ///
    func getUserStatusWithEmail(req: Request) throws -> EventLoopFuture<UserStatus> {
        guard let email = req.query[String.self, at: "email"] else {
            throw Exception.missingEmail
        }
        return User.query(on: req.db).filter(\.$email == email).first().flatMapThrowing { user in
            return UserStatus(email: email, exists: user != nil)
        }
    }
    
    /// Search Users
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///
    /// - Returns: [User.Public]
    ///
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
    
    /// Set Following Status
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///     - 400 - cannotFollowSelf - Users cannot follow/unfollow themselves.
    ///
    /// - Returns: HTTPStatus
    ///
    func setFollowingStatus(to newFollowingStatus: Bool, req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id,
                  let otherUserId = req.userId(defaultToIdOf: loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            return User.find(userId, on: req.db).flatMap { user in
                return User.find(otherUserId, on: req.db).flatMap { otherUser in
                    guard let user = user, let otherUser = otherUser else {
                        return req.fail(Exception.userDoesNotExist)
                    }
                    guard user.id != otherUser.id else {
                        return req.fail(Exception.cannotFollowSelf)
                    }
                    return self.updateFollowingStatus(req: req,
                                                      user: user,
                                                      otherUser: otherUser,
                                                      newFollowingStatus: newFollowingStatus)
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func follow(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try setFollowingStatus(to: true, req: req)
    }
    
    func unfollow(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try setFollowingStatus(to: false, req: req)
    }
    
    private func updateFollowingStatus(req: Request,
                                       user: User,
                                       otherUser: User,
                                       newFollowingStatus: Bool) -> EventLoopFuture<HTTPStatus> {
        return FollowingFollower.query(on: req.db)
            .filter(\.$follower.$id == user.id ?? UUID())
            .filter(\.$following.$id == otherUser.id ?? UUID())
            .first()
            .flatMap { existingConnection in
            if newFollowingStatus == true {
                guard existingConnection == nil else { return req.success(HTTPStatus.ok) }
                return user.$following.attach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
            } else {
                return user.$following.detach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
            }
        }
    }
    
    /// Get Follows
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - invalidFollowType - You must provide a follow type of followers or following.
    ///
    /// - Returns: [User.Public]
    ///
    func getFollows(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = req.userId(defaultToIdOf: loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            guard let followType = req.parameters.get("followType") else {
                return req.fail(Exception.invalidFollowType)
            }
            return follows(req: req, userId: userId, followType: followType)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func follows(req: Request, userId: UUID, followType: String) -> EventLoopFuture<[User.Public]> {
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
    
    /// Get Follows
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///
    /// - Returns: FollowStatus
    ///
    func getFollowStatus(req: Request) -> EventLoopFuture<FollowStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let loggedInUserId = loggedInUser.id,
                  let otherUserId = req.userId(defaultToIdOf: loggedInUser) else {
                return req.fail(Exception.invalidUserId)
            }
            let loggedInFollowingOther = getFutureConnection(req, loggedInUserId, otherUserId)
            let otherFollowingLoggedIn = getFutureConnection(req, otherUserId, loggedInUserId)
            let futures = loggedInFollowingOther.and(otherFollowingLoggedIn)
            return futures.flatMap {
                return req.success(FollowStatus(loggedInUserIsFollowingOtherUser: $0 != nil,
                                                otherUserIsFollowingLoggedInUser: $1 != nil))
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func getFutureConnection(_ req: Request,
                                     _ followerId: UUID,
                                     _ followingId: UUID) -> EventLoopFuture<FollowingFollower?> {
        return FollowingFollower.query(on: req.db)
            .filter(\.$follower.$id == followerId)
            .filter(\.$following.$id == followingId)
            .first()
    }
    
    /// Delete User
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 401 - userIsNotAdmin - User must be an admin to access or modify this resource.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///
    /// - Returns: HTTPStatus
    ///
    func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = req.userId(defaultToIdOf: loggedInUser) else {
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
            return req.fail(Exception.invalidUserId)
        }
        let deleteFollows = FollowingFollower.query(on: req.db).group(.or) { group in
            group.filter(\.$follower.$id == userId).filter(\.$following.$id == userId)
        }.delete()
        return deleteFollows
            .and(Post.query(on: req.db).filter(\.$user.$id == userId).delete())
            .and(Token.query(on: req.db).filter(\.$user.$id == userId).delete())
            .and(self.deleteProfilePhoto(req: req, userId: userId, user: user))
            .and(user.delete(on: req.db)).transform(to: HTTPStatus.ok)
    }
    
    /// Update User
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - missingUserUpdate - You must provide a valid user update object.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///     - 403 - userAlreadyExists - A user with the same email already exists.
    ///     - 500 - couldNotCreateUser - A user could not be created.
    ///
    /// - Returns: User.Public
    ///
    func updateUser(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userUpdate = try? req.content.decode(UserUpdate.self) else {
                return req.fail(Exception.missingUserUpdate)
            }
            guard let userId = req.userId(defaultToIdOf: loggedInUser) else {
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
                guard let email = userUpdate.email else { return self.saveUpdatedUser(user: user, req: req) }
                return self.saveUpdatedUserWithNewEmail(req: req, user: user, userId: userId, newEmail: email)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func saveUpdatedUserWithNewEmail(req: Request,
                                             user: User,
                                             userId: UUID,
                                             newEmail: String) -> EventLoopFuture<User.Public> {
        return User.query(on: req.db).filter(\.$email == newEmail).first().flatMap { existingUser in
            if let existingUser = existingUser, existingUser.id != userId {
                return req.fail(Exception.userAlreadyExists)
            }
            guard user.email != newEmail else { return self.saveUpdatedUser(user: user, req: req) }
            user.email = newEmail
            user.isEmailVerified = Settings.requireEmailVerification ? false : true
            return self.saveUpdatedUser(user: user, req: req)
        }
    }
    
    private func saveUpdatedUser(user: User, req: Request) -> EventLoopFuture<User.Public> {
        guard let publicUser = try? user.asPublic() else {
            return req.fail(Exception.couldNotCreateUser)
        }
        return user.save(on: req.db).transform(to: publicUser)
    }
    
    /// Upload Profile Photo
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - Invalid photo
    ///     - 400 - invalidImageType - Image must have an allowed extension.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist
    ///
    /// - Returns: ProfilePhotoUploadResponse
    ///
    func uploadProfilePhoto(req: Request) throws -> EventLoopFuture<ProfilePhotoUploadResponse> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id else {
                return req.fail(Exception.invalidUserId)
            }
            let photo = try req.content.decode(ProfilePhoto.self)
            guard let ext = photo.file.extension?.lowercased(),
                  Settings.allowedImageTypes.contains(ext) else {
                return req.fail(Exception.invalidImageType)
            }
            let profilePhotoInfo = ProfilePhotoInfo(req, userId, ext: ext)
            let putObjectRequest = S3.PutObjectRequest(acl: .publicRead,
                                                       body: AWSPayload.byteBuffer(photo.file.data),
                                                       bucket: Environment.s3Bucket,
                                                       key: profilePhotoInfo.filename)
            
            let url = profilePhotoInfo.awsUrl
            return deleteProfilePhoto(req: req, userId: userId, user: loggedInUser).flatMap { _ in
                return req.s3.putObject(putObjectRequest).flatMap { _ in
                    return self.saveProfilePhotoUrl(req: req, userId: userId, url: url).flatMap { exception in
                        if let exception = exception {
                            return req.fail(exception)
                        }
                        return req.success(ProfilePhotoUploadResponse(url: url))
                    }
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    /// Delete Profile Photo
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///     - 400 - invalidUserId - You must provide a valid user id.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist
    ///     - 500 - couldNotCreateProfilePhotoUrl - The existing profile photo url could not be created.
    ///
    /// - Returns: HTTPStatus
    ///
    func deleteProfilePhoto(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = loggedInUser.id else {
                return req.fail(Exception.invalidUserId)
            }
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                return self.deleteProfilePhoto(req: req, userId: userId, user: user).flatMap { _ in
                    user.profilePhotoUrl = nil
                    return user.save(on: req.db).transform(to: HTTPStatus.ok)
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func deleteProfilePhoto(req: Request, userId: UUID, user: User) -> EventLoopFuture<HTTPStatus> {
        guard let existingUrl = user.profilePhotoUrl else {
            return req.success(HTTPStatus.ok)
        }
        let info = ProfilePhotoInfo(req, userId, existingUrl: existingUrl)
        guard let key = info.existingFilename else {
            return req.fail(Exception.couldNotCreateProfilePhotoUrl)
        }
        let deleteObjectRequest = S3.DeleteObjectRequest(bucket: Environment.s3Bucket,
                                                         key: key)
        return req.s3.deleteObject(deleteObjectRequest).transform(to: HTTPStatus.ok)
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
