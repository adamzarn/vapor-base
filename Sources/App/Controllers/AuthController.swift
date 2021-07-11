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
        let passwordProtectedAuthRoute = authRoute.grouped(UserBasicAuthenticator())
        let tokenProtectedAuthRoute = authRoute.grouped(UserBearerAuthenticator())
        let passwordTokenProtectedRoute = authRoute
            .grouped(UserBasicAuthenticator())
            .grouped(UserBearerAuthenticator())

        authRoute.post(SessionSource.registration.pathComponent, use: register)
        passwordProtectedAuthRoute.post(SessionSource.login.pathComponent, use: login)
        tokenProtectedAuthRoute.delete("logout", use: logout)
        passwordTokenProtectedRoute.post("sendEmailVerificationEmail", use: sendEmailVerificationEmail)
        authRoute.put("verifyEmail", ":tokenId", use: verifyEmail)
        authRoute.post("sendPasswordResetEmail", use: sendPasswordResetEmail)
        authRoute.put("resetPassword", ":tokenId", use: resetPassword)
        
    }
    
    // MARK: Register
    
    func register(req: Request) throws -> EventLoopFuture<NewSession> {
        try UserData.validate(content: req)
        let user = try User.from(data: try req.content.decode(UserData.self))
        return User.query(on: req.db).filter(\.$email == user.email).first().flatMap { existingUser in
            guard existingUser == nil else {
                return req.fail(Exception.userAlreadyExists)
            }
            var token: Token!
            return user.save(on: req.db).flatMap {
                guard let newToken = try? user.createToken(source: .registration) else {
                    return req.fail(Exception.couldNotCreateToken)
                }
                token = newToken
                return token.save(on: req.db)
            }.flatMapThrowing {
                guard Settings.requireEmailVerification == false else { throw Exception.emailIsNotVerified }
                return NewSession(id: token.id?.uuidString ?? "", token: token.value, user: try user.asPublic())
            }
        }
    }
    
    // MARK: Login
    
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
    
    // MARK: Logout
    
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        do {
            let loggedInUser = try req.auth.require(User.self)
            return Token.query(on: req.db)
                .filter(\.$user.$id == loggedInUser.id ?? UUID())
                .group(.or) { group in
                    group.filter(\.$source == .registration).filter(\.$source == .login)
                }
                .delete()
                .transform(to: HTTPStatus.ok)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }
    
    // MARK: Send Email Verification Email
    
    func sendEmailVerificationEmail(req: Request) throws -> EventLoopFuture<String> {
        guard let emailVerification = try? req.content.decode(EmailVerification.self) else {
            return req.fail(Exception.missingEmailVerificationObject)
        }
        return sendEmail(req: req,
                         source: .emailVerification,
                         leafTemplate: .verifyEmailEmail,
                         email: emailVerification.email,
                         url: emailVerification.frontendBaseUrl)
    }
    
    // MARK: Verify Email
    
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
                    guard token.source == .emailVerification else {
                        return req.success(HTTPStatus.ok)
                    }
                    // Delete all email verification tokens for this user
                    return Token.query(on: req.db)
                        .filter(\.$user.$id == user.id ?? UUID())
                        .filter(\.$source == SessionSource.emailVerification)
                        .delete().transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
    // MARK: Send Password Reset Email
    
    func sendPasswordResetEmail(req: Request) throws -> EventLoopFuture<String> {
        guard let passwordReset = try? req.content.decode(PasswordReset.self) else {
            return req.fail(Exception.missingPasswordResetObject)
        }
        return sendEmail(req: req,
                         source: .passwordReset,
                         leafTemplate: .passwordResetEmail,
                         email: passwordReset.email,
                         url: passwordReset.frontendBaseUrl)
    }
    
    // MARK: Reset Password
    
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
                guard let user = user else {
                    return req.fail(Exception.userDoesNotExist)
                }
                guard let newPassword = try? req.content.decode(NewPassword.self) else {
                    return req.fail(Exception.missingPassword)
                }
                guard let passwordHash = try? Bcrypt.hash(newPassword.value) else {
                    return req.fail(Exception.couldNotCreatePasswordHash)
                }
                user.passwordHash = passwordHash
                return user.save(on: req.db).flatMap {
                    guard token.source == .passwordReset else {
                        return req.success(HTTPStatus.ok)
                    }
                    // Delete all password reset tokens for this user
                    return Token.query(on: req.db)
                        .filter(\.$user.$id == user.id ?? UUID())
                        .filter(\.$source == SessionSource.passwordReset)
                        .delete().transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
    // MARK: Send Email
    
    func sendEmail(req: Request,
                   source: SessionSource,
                   leafTemplate: LeafTemplate,
                   email: String,
                   url: String) -> EventLoopFuture<String> {
        return User.query(on: req.db).filter(\.$email == email).first().flatMap { user in
            guard let user = user else {
                return req.fail(Exception.userDoesNotExist)
            }
            guard let token = try? user.createToken(source: source) else {
                return req.fail(Exception.couldNotCreateToken)
            }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else {
                    return req.fail(Exception.invalidToken)
                }
                guard !req.testing else { return req.success(tokenId) }
                let context = EmailContext(user: user,
                                           url: "\(url)/\(tokenId)",
                                           leafTemplate: leafTemplate)
                return req.sendEmail(to: user, tokenId: tokenId, context: context)
            }
        }
    }
}
