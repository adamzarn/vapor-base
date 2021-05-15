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
        usersRoute.get("status", use: getUserStatusWithEmail)
        
        let tokenProtectedUsersRoute = usersRoute.grouped(UserBearerAuthenticator())
        tokenProtectedUsersRoute.get(":userId", use: getUser)
        tokenProtectedUsersRoute.get("search", use: searchUsers)
        tokenProtectedUsersRoute.post(":userId", "setFollowingStatus", use: setFollowingStatus)
        tokenProtectedUsersRoute.get(":userId", "followers", use: getFollowers)
        tokenProtectedUsersRoute.get(":userId", "following", use: getFollowing)
        tokenProtectedUsersRoute.delete(":userId", use: deleteUser)
        tokenProtectedUsersRoute.put(use: updateUser)
        tokenProtectedUsersRoute.put(":userId", "setAdminStatus", use: setAdminStatus)
        
    }
    
    func getUserStatusWithEmail(req: Request) throws -> EventLoopFuture<UserStatus> {
        guard let email = req.query[String.self, at: "email"] else {
            throw Exception.missingEmail
        }
        return User.query(on: req.db).filter(\.$email == email).first().flatMapThrowing { existingUser in
            guard existingUser != nil else { return UserStatus(email: email, exists: false) }
            return UserStatus(email: email, exists: true)
        }
    }
    
    func getUser(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userId = getUserId(loggedInUser: loggedInUser, req: req) else { return req.fail(Exception.missingUserId) }
            return User.find(userId, on: req.db).flatMapThrowing { user in
                guard let user = user else { throw Exception.userDoesNotExist }
                return try user.asPublic()
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func searchUsers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let _ = try AuthUtility.getAuthorizedUser(req: req)
            let query = req.query[String.self, at: "query"] ?? ""
            let (start, end) = getSearchRange(req: req)
            let queryBuilder = User.query(on: req.db).group(.or) { group in
                group.filter(\.$firstName, .caseInsensitiveContains, "%\(query)%")
                    .filter(\.$lastName, .caseInsensitiveContains, "%\(query)%")
                    .filter(\.$username, .caseInsensitiveContains, "%\(query)%")
                    .filter(\.$email, .caseInsensitiveContains, "%\(query)%")
            }
            let futureUsers = addAdminFilter(to: queryBuilder, req: req, start: start, end: end)
            return futureUsers.flatMapThrowing { users in
                return try users.compactMap { try $0.asPublic() }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    private func addAdminFilter(to queryBuilder: QueryBuilder<User>, req: Request, start: Int, end: Int) -> EventLoopFuture<[User]> {
        if let isAdminString = req.query[String.self, at: "isAdmin"], ["yes", "no"].contains(isAdminString) {
            let isAdmin = isAdminString == "yes"
            let queryBuilder = queryBuilder.filter(\.$isAdmin == isAdmin)
            // Return all results if only retrieving admins
            return isAdmin ? queryBuilder.all() : queryBuilder.range(start..<end).all()
        } else {
            return queryBuilder.range(start..<end).all()
        }
    }
    
    private func getSearchRange(req: Request) -> (Int, Int) {
        guard let start = req.query[Int.self, at: "start"] else { return (0, Constants.searchResultLimit) }
        guard let end = req.query[Int.self, at: "end"], end >= start else { return (start, start + Constants.searchResultLimit) }
        return (start, end)
    }
    
    func setFollowingStatus(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let followerId = getUserId(loggedInUser: loggedInUser, req: req) else { return req.fail(Exception.missingUserId) }
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: followerId != loggedInUser.id && !loggedInUser.isAdmin)
            guard let newFollowingStatus = try? req.content.decode(NewFollowingStatus.self) else {
                return req.fail(Exception.missingFollowingStatus)
            }
            return User.find(followerId, on: req.db).flatMap { user in
                return User.find(newFollowingStatus.otherUserId, on: req.db).flatMap { otherUser in
                    guard let user = user, let otherUser = otherUser else {
                        return req.fail(Exception.userDoesNotExist)
                    }
                    // Check if user is already following other user
                    return FollowingFollower.query(on: req.db)
                        .filter(\.$follower.$id == user.id ?? UUID())
                        .filter(\.$following.$id == otherUser.id ?? UUID())
                        .first()
                        .flatMap { existingConnection in
                        if newFollowingStatus.follow {
                            guard existingConnection == nil else { return req.success(HTTPStatus.ok) }
                            guard user.id != otherUser.id else { return req.fail(Exception.cannotFollowSelf) }
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
    
    func getFollowers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = getUserId(loggedInUser: loggedInUser, req: req) else { return req.fail(Exception.missingUserId) }
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: userId != loggedInUser.id && Constants.onlyAdminsCanGetFollowersOfAnyUser)
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                return self.followers(of: user, req: req)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func getFollowing(req: Request) throws -> EventLoopFuture<[User.Public]> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = getUserId(loggedInUser: loggedInUser, req: req) else { return req.fail(Exception.missingUserId) }
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: userId != loggedInUser.id && Constants.onlyAdminsCanGetFollowingOfAnyUser)
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                return self.following(of: user, req: req)
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
    
    func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            guard let userId = getUserId(loggedInUser: loggedInUser, req: req) else {
                return req.fail(Exception.missingUserId)
            }
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: userId != loggedInUser.id)
            return User.find(userId, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                return self.delete(user: user, req: req)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func delete(user: User, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let userId = user.id else { return req.fail(Exception.missingUserId) }
        // Delete following/follower records for this user
        return FollowingFollower.query(on: req.db).group(.or) { group in
            group.filter(\.$follower.$id == userId).filter(\.$following.$id == userId)
        }.delete().flatMap {
            // Delete all tokens for this user
            return Token.query(on: req.db).filter(\.$user.$id == userId).delete().flatMap {
                // Delete user
                return user.delete(on: req.db).transform(to: HTTPStatus.ok)
            }
        }
    }
    
    func updateUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            guard let userUpdate = try? req.content.decode(UserUpdate.self) else {
                return req.fail(Exception.missingUserUpdate)
            }
            return User.find(loggedInUser.id, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                if let firstName = userUpdate.firstName { user.firstName = firstName }
                if let lastName = userUpdate.lastName { user.lastName = lastName }
                if let username = userUpdate.username { user.username = username }
                return user.save(on: req.db).transform(to: HTTPStatus.ok)
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func setAdminStatus(req: Request) throws -> EventLoopFuture<User.Public> {
        do {
            let _ = try AuthUtility.getAuthorizedUser(req: req, mustBeAdmin: true)
            guard let newAdminStatus = try? req.content.decode(NewAdminStatus.self) else {
                return req.fail(Exception.missingAdminStatus)
            }
            guard let userId = req.parameters.get("userId") else {
                return req.fail(Exception.missingUserId)
            }
            return User.find(UUID(uuidString: userId), on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                user.isAdmin = newAdminStatus.isAdmin
                return user.save(on: req.db).flatMapThrowing { try user.asPublic() }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func getUserId(loggedInUser: User, req: Request) -> UUID? {
        var userId = req.parameters.get("userId") ?? "me"
        if userId == "me" { userId = loggedInUser.id?.uuidString ?? "" }
        return UUID(userId)
    }
}
