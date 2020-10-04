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

class UsersController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let usersRoute = routes.grouped(User.pathComponent)
        // Signup
        usersRoute.post(SessionSource.signup.pathComponent, use: createUser)
        
        let passwordProtectedUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator())
        // Login
        passwordProtectedUsersRoute.post(SessionSource.login.pathComponent, use: login)
        
        // All routes besides signup/login can be authenticated using basic or bearer authorization
        let tokenProtectedUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator())
            .grouped(UserBearerAuthenticator())

        tokenProtectedUsersRoute.get("me", use: getMyOwnUser)
        tokenProtectedUsersRoute.post("setFollowingStatus", use: setFollowingStatus)
        tokenProtectedUsersRoute.get("me", "followers", use: getMyFollowers)
        tokenProtectedUsersRoute.get("me", "following", use: getMyFollowing)
        tokenProtectedUsersRoute.delete("me", use: deleteMyUser)
        
        let tokenProtectedAdminUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator(adminsOnly: true))
            .grouped(UserBearerAuthenticator(adminsOnly: true))
        
        tokenProtectedAdminUsersRoute.get(use: getAllUsers)
        tokenProtectedAdminUsersRoute.get(":userId", "followers", use: getFollowers)
        tokenProtectedAdminUsersRoute.get(":userId", "following", use: getFollowing)
        tokenProtectedAdminUsersRoute.put("setAdminStatus", use: setAdminStatus)
        tokenProtectedAdminUsersRoute.delete(":userId", use: deleteUser)
        
    }
    
    func createUser(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserData.validate(content: req)
        let user = try User.from(data: try req.content.decode(UserData.self))
        var token: Token!
        return User.query(on: req.db)
            .filter(\.$email == user.email)
            .first()
            .flatMap { existingUser in
            guard existingUser == nil else {
                return req.fail(CustomAbort.userAlreadyExists)
            }
            return user.save(on: req.db).flatMap {
                guard let newToken = try? user.createToken(source: .signup) else {
                    return req.fail(Abort(.internalServerError))
                }
                token = newToken
                return token.save(on: req.db)
            }.flatMapThrowing {
                if let requireEmailVerification = req.query[Bool.self, at: "requireEmailVerification"], requireEmailVerification {
                    self.sendWelcomeEmail(to: user, req: req)
                }
                return NewSession(token: token.value, user: try user.asPublic())
            }
        }
    }
    
    func sendWelcomeEmail(to newUser: User, req: Request) {
        let message = MailgunMessage(from: "alyssazarn@gmail.com",
                                     to: newUser.email,
                                     subject: "Welcome!",
                                     text: "Hi \(newUser.firstName)",
                                     html: "<h1>We're glad to have you!</h1>")
        let send = req.mailgun().send(message)
        send.whenSuccess { response in
            print("Success: \(response)")
        }
        send.whenFailure { response in
            print("Failure: \(response)")
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        let token = try user.createToken(source: .login)
        // Delete any old tokens for this user
        return Token.query(on: req.db).filter(\.$user.$id == user.id ?? UUID()).delete().flatMap {
            // Save new token
            return token.save(on: req.db).flatMapThrowing {
                NewSession(token: token.value, user: try user.asPublic())
            }
        }
    }
    
    func getAllUsers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let _ = try req.auth.require(User.self)
        return User.query(on: req.db).all().flatMapThrowing { users in
            return try users.compactMap { try $0.asPublic() }
        }
    }
    
    func getMyOwnUser(req: Request) throws -> User.Public {
        let user = try req.auth.require(User.self)
        return try user.asPublic()
    }
    
    func setAdminStatus(req: Request) throws -> EventLoopFuture<User.Public> {
        let _ = try req.auth.require(User.self)
        guard let userId = req.query[UUID.self, at: "userId"] else {
            return req.fail(CustomAbort.missingUserId)
        }
        guard let isAdmin = req.query[Bool.self, at: "isAdmin"] else {
            return req.fail(CustomAbort.missingAdminStatus)
        }
        return User.find(userId, on: req.db).flatMap {
            guard let user = $0 else { return req.fail(CustomAbort.userDoesNotExist) }
            user.isAdmin = isAdmin
            return user.save(on: req.db).flatMapThrowing { try user.asPublic() }
        }
    }
    
    func setFollowingStatus(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let me = try req.auth.require(User.self)
        guard let otherUserId = req.query[UUID.self, at: "otherUserId"] else {
            return req.fail(CustomAbort.missingUserId)
        }
        guard let follow = req.query[Bool.self, at: "follow"] else {
            return req.fail(CustomAbort.missingFollowingStatus)
        }
        return User.find(otherUserId, on: req.db).flatMap {
            guard let otherUser = $0 else { return req.fail(CustomAbort.userDoesNotExist) }
            guard me.id != otherUser.id else { return req.fail(CustomAbort.cannotFollowSelf) }
            if follow {
                return me.$following.attach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
            } else {
                return me.$following.detach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
            }
        }
    }
    
    func getMyFollowers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let me = try req.auth.require(User.self)
        return followers(of: me, req: req)
    }
    
    func getMyFollowing(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let me = try req.auth.require(User.self)
        return following(of: me, req: req)
    }
    
    func getFollowers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        _ = try req.auth.require(User.self)
        return User.find(req.parameters.get("userId"), on: req.db).flatMap {
            guard let user = $0 else { return req.fail(CustomAbort.userDoesNotExist) }
            return self.followers(of: user, req: req)
        }
    }
    
    func getFollowing(req: Request) throws -> EventLoopFuture<[User.Public]> {
        _ = try req.auth.require(User.self)
        return User.find(req.parameters.get("userId"), on: req.db).flatMap {
            guard let user = $0 else { return req.fail(CustomAbort.userDoesNotExist) }
            return self.following(of: user, req: req)
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
    
    func deleteMyUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return delete(user: user, req: req)
    }
    
    func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let _ = try req.auth.require(User.self)
        return User.find(req.parameters.get("userId"), on: req.db).flatMap {
            guard let user = $0 else { return req.fail(CustomAbort.userDoesNotExist) }
            return self.delete(user: user, req: req)
        }
    }
    
    func delete(user: User, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let userId = user.id else { return req.fail(CustomAbort.missingUserId) }
        // Delete all tokens for this user
        return Token.query(on: req.db).filter(\.$user.$id == userId).delete().flatMap {
            // Delete user
            return user.delete(on: req.db).transform(to: HTTPStatus.ok)
        }
    }
    
}
