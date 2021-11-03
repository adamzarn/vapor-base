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
    
    /// Register
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - Invalid UserData
    ///     - 403 - userAlreadyExists - A user with same email already exists.
    ///     - 500 - couldNotCreateToken - A token could not be generated.
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///
    /// - Returns: NewSession
    ///
    func register(req: Request) throws -> EventLoopFuture<NewSession> {
        guard let deviceId = req.deviceId else {
            return req.fail(Exception.missingDeviceId)
        }
        try UserData.validate(content: req)
        let user = try User.from(data: try req.content.decode(UserData.self))
        return User.query(on: req.db).filter(\.$email == user.email).first().flatMap { existingUser in
            guard existingUser == nil else {
                return req.fail(Exception.userAlreadyExists)
            }
            var token: Token!
            return user.save(on: req.db).flatMap {
                guard let newToken = try? user.createToken(deviceId: deviceId, source: .registration) else {
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
    
    /// Login
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///
    /// - Returns: NewSession
    ///
    func login(req: Request) throws -> EventLoopFuture<NewSession> {
        guard let deviceId = req.deviceId else {
            return req.fail(Exception.missingDeviceId)
        }
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            let token = try loggedInUser.createToken(deviceId: deviceId, source: .login)
            // Delete any old access tokens for this device and user
            return Token.query(on: req.db)
                .filter(\.$deviceId == deviceId)
                .filter(\.$user.$id == loggedInUser.id ?? UUID())
                .group(.or) { group in
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
    
    /// Logout
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///
    /// - Returns: HTTPStatus
    ///
    func logout(req: Request) throws -> EventLoopFuture<HTTPStatus> {
        guard let deviceId = req.deviceId else {
            return req.fail(Exception.missingDeviceId)
        }
        do {
            let loggedInUser = try AuthUtility.getAuthorizedUser(req: req)
            return Token.query(on: req.db)
                .filter(\.$deviceId == deviceId)
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
    
    /// Send Email Verification Email
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - missingEmailVerificationObject - You must provide an email and a frontendBaseUrl.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///     - 500 - couldNotCreateToken - An email verification token could not be generated.
    ///     - 500 - couldNotGenerateTokenId - The email verification token id could not be generated.
    ///
    /// - Returns: String
    ///
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
    
    /// Verify Email
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - missingTokenId - You must provide a token id.
    ///     - 401 - invalidToken - The provided token is either expired or it is not associated with any user.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///
    /// - Returns: HTTPStatus
    ///
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
                    // Delete all email verification tokens for this user
                    return Token.query(on: req.db)
                        .filter(\.$user.$id == user.id ?? UUID())
                        .filter(\.$source == SessionSource.emailVerification)
                        .delete().transform(to: HTTPStatus.ok)
                }
            }
        }
    }
    
    /// Send Password Reset Email
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - missingPasswordResetObject - You must provide an email and a frontendBaseUrl.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///     - 500 - couldNotCreateToken - A password reset token could not be generated.
    ///     - 500 - couldNotGenerateTokenId - The password reset token id coud not be generated.
    ///
    /// - Returns: String
    ///
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
    
    /// Reset Password
    ///
    /// - Possible Errors (in order of execution):
    ///     - 400 - Invalid NewPassword
    ///     - 400 - missingTokenId - You must provide a token id.
    ///     - 401 - invalidToken - The provided token is either expired or it is not associated with any user.
    ///     - 400 - userDoesNotExist - A user with the specified id does not exist.
    ///     - 400 - missingPassword - You must provide a new password to update a user's password.
    ///     - 500 - couldNotCreatePasswordHash - The password could not be hashed.
    ///
    /// - Returns: HTTPStatus
    ///
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
            guard let token = try? user.createToken(deviceId: "", source: source) else {
                return req.fail(Exception.couldNotCreateToken)
            }
            return token.save(on: req.db).flatMap {
                guard let tokenId = token.id?.uuidString else {
                    return req.fail(Exception.couldNotGenerateTokenId)
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
