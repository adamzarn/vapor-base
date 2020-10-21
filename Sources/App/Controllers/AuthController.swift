//
//  AuthController.swift
//  App
//
//  Created by Adam Zarn on 10/14/20.
//

import Foundation
import Vapor
import Fluent
import Mailgun

class AuthController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let authRoute = routes.grouped("auth")
        if Constants.requireEmailVerification {
            authRoute.post(SessionSource.registration.pathComponent, use: registerWithEmailVerification)
        } else {
            authRoute.post(SessionSource.registration.pathComponent, use: registerAndLogin)
        }
        authRoute.put("resetPassword", ":tokenId", use: resetPassword)
        authRoute.post("sendPasswordResetEmail", ":email", use: sendPasswordResetEmail)

        let passwordProtectedAuthRoute = authRoute.grouped(UserBasicAuthenticator())
        passwordProtectedAuthRoute.post("sendEmailVerificationEmail", use: sendEmailVerificationEmail)
        passwordProtectedAuthRoute.post(SessionSource.login.pathComponent, use: login)
        
        let tokenProtectedAuthRoute = authRoute.grouped(UserBearerAuthenticator())
        tokenProtectedAuthRoute.delete("logout", use: logout)
        
    }
    
    func registerAndLogin(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserData.validate(content: req)
        let user = try User.from(data: try req.content.decode(UserData.self))
        return User.query(on: req.db).filter(\.$email == user.email).first().flatMap { existingUser in
            guard existingUser == nil else { return req.fail(CustomAbort.userAlreadyExists) }
            var token: Token!
            return user.save(on: req.db).flatMap {
                guard let newToken = try? user.createToken(source: .registration) else {
                    return req.fail(CustomAbort.couldNotCreateToken)
                }
                token = newToken
                return token.save(on: req.db)
            }.flatMapThrowing {
                return NewSession(id: token.id?.uuidString ?? "", token: token.value, user: try user.asPublic())
            }
        }
    }
    
    func registerWithEmailVerification(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        try UserData.validate(content: req)
        let user = try User.from(data: try req.content.decode(UserData.self))
        return User.query(on: req.db).filter(\.$email == user.email).first().flatMap { existingUser in
            guard existingUser == nil else { return req.fail(CustomAbort.userAlreadyExists) }
            // User will be created but cannot login until email is verified
            return user.save(on: req.db).flatMap {
                self.sendEmailVerificationEmail(to: user, req: req)
            }
        }
    }
    
    func sendEmailVerificationEmail(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return self.sendEmailVerificationEmail(to: user, req: req)
    }
    
    func sendEmailVerificationEmail(to user: User?, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
        return Token.query(on: req.db)
            .filter(\.$user.$id == user.id ?? UUID())
            .filter(\.$source == .emailVerification)
            .delete().flatMap {
            guard let token = try? user.createToken(source: .emailVerification) else {
                return req.fail(CustomAbort.couldNotCreateToken)
            }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else { return req.fail(CustomAbort.invalidToken) }
                let verifyEmailUrl = "\(req.baseUrl)/view/verifyEmail/\(tokenId)"
                let context = EmailVerificationEmailContext(name: user.firstName, verifyEmailUrl: verifyEmailUrl)
                return req.view.render("verify-email-email", context).flatMapThrowing { view in
                    let html = String(buffer: view.data)
                    let message = MailgunMessage(from: MailConstants.from,
                                                 to: user.email,
                                                 subject: "Please verify your email",
                                                 text: "",
                                                 html: html)
                    _ = req.mailgun().send(message).always { response in
                        print(response)
                    }
                    return HTTPStatus.ok
                }
            }
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<NewSession> {
        let user = try req.auth.require(User.self)
        if Constants.requireEmailVerification && !user.isEmailVerified {
            return req.fail(CustomAbort.emailIsNotVerified)
        }
        let token = try user.createToken(source: .login)
        // Delete any old access tokens for this user
        return Token.query(on: req.db).filter(\.$user.$id == user.id ?? UUID()).group(.or) { group in
            group.filter(\.$source == .registration).filter(\.$source == .login)
        }.delete().flatMap {
            // Save new token
            return token.save(on: req.db).flatMapThrowing {
                NewSession(id: token.id?.uuidString ?? "", token: token.value, user: try user.asPublic())
            }
        }
    }
    
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        let user = try req.auth.require(User.self)
        return Token.query(on: req.db).filter(\.$user.$id == user.id ?? UUID()).delete().transform(to: HTTPStatus.ok)
    }
    
    func sendPasswordResetEmail(req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let email = req.parameters.get("email") else { return req.fail(CustomAbort.missingEmail) }
        return User.query(on: req.db).filter(\.$email == email).first().flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            guard let token = try? user.createToken(source: .passwordReset) else { return req.fail(CustomAbort.couldNotCreateToken) }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else { return req.fail(CustomAbort.invalidToken) }
                let passwordResetUrl = "\(req.baseUrl)/view/passwordReset/\(tokenId)"
                let context = PasswordResetEmailContext(name: user.firstName, passwordResetUrl: passwordResetUrl)
                return req.view.render("password-reset-email", context).flatMapThrowing { view in
                    let html = String(buffer: view.data)
                    let message = MailgunMessage(from: MailConstants.from,
                                                 to: user.email,
                                                 subject: "Password Reset",
                                                 text: "",
                                                 html: html)
                    _ = req.mailgun().send(message).always { response in
                        print(response)
                    }
                    return HTTPStatus.ok
                }
            }
        }
    }
    
    func resetPassword(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        return Token.find(req.parameters.get("tokenId"), on: req.db).flatMap { token in
            guard let token = token, token.source.isValidForPasswordReset, token.isValid else {
                return req.fail(CustomAbort.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
                guard let newPassword = try? req.content.decode(NewPassword.self) else { return req.fail(CustomAbort.missingPassword) }
                guard let passwordHash = try? Bcrypt.hash(newPassword.value) else { return req.fail(CustomAbort.couldNotCreatePasswordHash) }
                user.passwordHash = passwordHash
                return user.save(on: req.db).transform(to: HTTPStatus.ok)
            }
        }
    }

}
