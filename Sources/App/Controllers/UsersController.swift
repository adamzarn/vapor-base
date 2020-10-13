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
        usersRoute.post(SessionSource.signup.pathComponent, use: createUser)
        usersRoute.get(":userId", "verifyEmail", use: verifyEmail)
        
        let passwordProtectedUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator())
        passwordProtectedUsersRoute.post(SessionSource.login.pathComponent, use: login)
        
        let tokenProtectedUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator())
            .grouped(UserBearerAuthenticator())

        tokenProtectedUsersRoute.get(":userId", use: getUser)
        tokenProtectedUsersRoute.post(":userId", "setFollowingStatus", use: setFollowingStatus)
        
        let tokenProtectedAdminUsersRoute = usersRoute
            .grouped(UserBasicAuthenticator(adminsOnly: true))
            .grouped(UserBearerAuthenticator(adminsOnly: true))
        
        tokenProtectedAdminUsersRoute.get(use: getAllUsers)
        tokenProtectedAdminUsersRoute.get(":userId", "followers", use: getFollowers)
        tokenProtectedAdminUsersRoute.get(":userId", "following", use: getFollowing)
        tokenProtectedAdminUsersRoute.put(":userId", "setAdminStatus", use: setAdminStatus)
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
                if Constants.requireEmailVerification {
                    self.sendEmailVerificationEmail(to: user, req: req)
                }
                return NewSession(token: token.value, user: try user.asPublic())
            }
        }
    }
    
    func sendEmailVerificationEmail(to newUser: User, req: Request) {
        guard let userId = newUser.id else { return }
        struct Context: Codable {
            let name: String
            let verifyEmailUrl: String
        }
        let verifyEmailUrl = "\(req.baseUrl)/users/\(userId.uuidString)/verifyEmail"
        let context = Context(name: newUser.firstName, verifyEmailUrl: verifyEmailUrl)
        let futureView = req.view.render("verify-email", context)
        _ = futureView.flatMapThrowing { view in
            let html = String(buffer: view.data)
            let message = MailgunMessage(from: MailConstants.from,
                                         to: newUser.email,
                                         subject: "Please verify your email",
                                         text: "",
                                         html: html)
            _ = req.mailgun().send(message).always { response in
                print(response)
            }
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
    
    func getUser(req: Request) throws -> EventLoopFuture<User.Public> {
        let me = try req.auth.require(User.self)
        guard let userId = getUserId(me: me, req: req) else { return req.fail(CustomAbort.missingUserId) }
        return User.find(userId, on: req.db).flatMapThrowing { user in
            guard let user = user else { throw CustomAbort.userDoesNotExist }
            return try user.asPublic()
        }
    }
    
    func setAdminStatus(req: Request) throws -> EventLoopFuture<User.Public> {
        let _ = try req.auth.require(User.self)
        guard let newAdminStatus = try? req.content.decode(NewAdminStatus.self) else {
            return req.fail(CustomAbort.missingAdminStatus)
        }
        return User.find(req.parameters.get("userId"), on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            user.isAdmin = newAdminStatus.isAdmin
            return user.save(on: req.db).flatMapThrowing { try user.asPublic() }
        }
    }
    
    func setFollowingStatus(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let me = try req.auth.require(User.self)
        guard let newFollowingStatus = try? req.content.decode(NewFollowingStatus.self) else {
            return req.fail(CustomAbort.missingFollowingStatus)
        }
        guard let followerId = getUserId(me: me, req: req) else { return req.fail(CustomAbort.missingUserId) }
        return User.find(followerId, on: req.db).flatMap { user in
            return User.find(newFollowingStatus.otherUserId, on: req.db).flatMap { otherUser in
                guard let user = user, let otherUser = otherUser else {
                    return req.fail(CustomAbort.userDoesNotExist)
                }
                // Check if user is already following other user
                return FollowingFollower.query(on: req.db)
                    .filter(\.$follower.$id == user.id ?? UUID())
                    .filter(\.$following.$id == otherUser.id ?? UUID())
                    .first()
                    .flatMap { existingConnection in
                    if newFollowingStatus.follow {
                        guard existingConnection == nil else { return req.success(HTTPStatus.ok) }
                        guard user.id != otherUser.id else { return req.fail(CustomAbort.cannotFollowSelf) }
                        return user.$following.attach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
                    } else {
                        return user.$following.detach(otherUser, on: req.db).transform(to: HTTPStatus.ok)
                    }
                }
            }
        }
    }
    
    func getFollowers(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let me = try req.auth.require(User.self)
        guard let userId = getUserId(me: me, req: req) else { return req.fail(CustomAbort.missingUserId) }
        return User.find(userId, on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            return self.followers(of: user, req: req)
        }
    }
    
    func getFollowing(req: Request) throws -> EventLoopFuture<[User.Public]> {
        let me = try req.auth.require(User.self)
        guard let userId = getUserId(me: me, req: req) else { return req.fail(CustomAbort.missingUserId) }
        return User.find(userId, on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
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
    
    func deleteUser(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let me = try req.auth.require(User.self)
        guard let userId = getUserId(me: me, req: req) else { return req.fail(CustomAbort.missingUserId) }
        return User.find(userId, on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            return self.delete(user: user, req: req)
        }
    }
    
    func delete(user: User, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let userId = user.id else { return req.fail(CustomAbort.missingUserId) }
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
    
    func verifyEmail(req: Request) throws -> EventLoopFuture<View> {
        return User.find(req.parameters.get("userId"), on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            user.isEmailVerified = true
            return user.save(on: req.db).flatMap {
                return req.view.render("email-verified")
            }
        }
    }
    
    func getUserId(me: User, req: Request) -> UUID? {
        var userId = req.parameters.get("userId") ?? ""
        if userId == "me" { userId = me.id?.uuidString ?? "" }
        return UUID(userId)
    }
    
}
