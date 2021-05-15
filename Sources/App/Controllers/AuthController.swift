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
        authRoute.post("sendPasswordResetEmail", use: sendPasswordResetEmail)
        authRoute.put("verifyEmail", ":tokenId", use: verifyEmail)

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
            guard existingUser == nil else { return req.fail(Exception.userAlreadyExists) }
            var token: Token!
            return user.save(on: req.db).flatMap {
                guard let newToken = try? user.createToken(source: .registration) else {
                    return req.fail(Exception.couldNotCreateToken)
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
            guard existingUser == nil else { return req.fail(Exception.userAlreadyExists) }
            // User will be created but cannot login until email is verified
            return user.save(on: req.db).flatMap {
                let _ = self.sendEmailVerificationEmail(to: user, req: req)
                return req.fail(Exception.emailIsNotVerified)
            }
        }
    }
    
    func login(req: Request) throws -> EventLoopFuture<NewSession> {
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            let token = try loggedInUser.createToken(source: .login)
            // Delete any old access tokens for this user
            return Token.query(on: req.db).filter(\.$user.$id == loggedInUser.id ?? UUID()).group(.or) { group in
                group.filter(\.$source == .registration).filter(\.$source == .login)
            }.delete().flatMap {
                // Save new token
                return token.save(on: req.db).flatMapThrowing {
                    NewSession(id: token.id?.uuidString ?? "", token: token.value, user: try loggedInUser.asPublic())
                }
            }
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            return Token.query(on: req.db)
                .filter(\.$user.$id == loggedInUser.id ?? UUID())
                .delete()
                .transform(to: HTTPStatus.ok)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func sendEmailVerificationEmail(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            return self.sendEmailVerificationEmail(to: loggedInUser, req: req)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    func sendEmailVerificationEmail(to user: User?, req: Request) -> EventLoopFuture<HTTPStatus> {
        guard let user = user else { return req.fail(Exception.userDoesNotExist) }
        return Token.query(on: req.db)
            .filter(\.$user.$id == user.id ?? UUID())
            .filter(\.$source == .emailVerification)
            .delete().flatMap {
            guard let token = try? user.createToken(source: .emailVerification) else {
                return req.fail(Exception.couldNotCreateToken)
            }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else { return req.fail(Exception.invalidToken) }
                var verifyEmailUrl: String
                if let frontendBaseUrl = try? req.content.decode(UserData.self).frontendBaseUrl {
                    verifyEmailUrl = "\(frontendBaseUrl)/\(tokenId)"
                } else {
                    verifyEmailUrl = "\(req.baseUrl)/view/verifyEmail/\(tokenId)"
                }
                let context = EmailVerificationEmailContext(name: user.firstName, verifyEmailUrl: verifyEmailUrl)
                return req.leaf.render(LeafTemplate.verifyEmailEmail.rawValue, context).flatMapThrowing { view in
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
    
    func sendPasswordResetEmail(req: Request) -> EventLoopFuture<HTTPStatus> {
        let passwordReset = try? req.content.decode(PasswordReset.self)
        guard let email = passwordReset?.email else { return req.fail(Exception.missingEmail) }
        return User.query(on: req.db).filter(\.$email == email).first().flatMap { user in
            guard let user = user else { return req.fail(Exception.userDoesNotExist) }
            guard let token = try? user.createToken(source: .passwordReset) else { return req.fail(Exception.couldNotCreateToken) }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else { return req.fail(Exception.invalidToken) }
                let passwordResetBaseUrl = passwordReset?.url ?? "\(req.baseUrl)/view/passwordReset/"
                let passwordResetUrl = "\(passwordResetBaseUrl)\(tokenId)"
                let context = PasswordResetEmailContext(name: user.firstName, passwordResetUrl: passwordResetUrl)
                return req.leaf.render(LeafTemplate.passwordResetEmail.rawValue, context).flatMapThrowing { view in
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
        try NewPassword.validate(content: req)
        guard let tokenId = req.parameters.get("tokenId") else {
            return req.fail(Exception.missingTokenId)
        }
        return Token.find(UUID(uuidString: tokenId), on: req.db).flatMap { token in
            guard let token = token, token.source.isValidForPasswordReset, token.isValid else {
                return req.fail(Exception.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(Exception.userDoesNotExist) }
                guard let newPassword = try? req.content.decode(NewPassword.self) else {
                    return req.fail(Exception.missingPassword)
                }
                guard let passwordHash = try? Bcrypt.hash(newPassword.value) else {
                    return req.fail(Exception.couldNotCreatePasswordHash)
                }
                user.passwordHash = passwordHash
                return user.save(on: req.db).flatMap {
                    return token.delete(on: req.db).transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
    func verifyEmail(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let tokenId = req.parameters.get("tokenId") else {
            return req.fail(Exception.missingTokenId)
        }
        return Token.find(UUID(uuidString: tokenId), on: req.db).flatMap { token in
            guard let token = token, token.source == .emailVerification, token.isValid else {
                return req.fail(Exception.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                user.isEmailVerified = true
                return user.save(on: req.db).flatMap {
                    return token.delete(on: req.db).transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
}
