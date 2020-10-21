//
//  ViewController.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation
import Vapor
import Leaf

class ViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
                
        let viewRoute = routes.grouped("view")
        viewRoute.get("home", use: homeView)
        viewRoute.get("register", use: registerView)
        viewRoute.get("login", use: loginView)
        viewRoute.get("profile", ":userId", use: profileView)
        viewRoute.get("verifyEmail", ":tokenId", use: verifyEmailView)
        viewRoute.get("passwordReset", ":tokenId", use: passwordResetView)
        
    }
    
    func homeView(req: Request) -> EventLoopFuture<View> {
        return req.view.render("home", BaseContext(baseUrl: req.baseUrl))
    }
    
    func registerView(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("register", BaseContext(baseUrl: req.baseUrl))
    }
    
    func loginView(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("login", BaseContext(baseUrl: req.baseUrl))
    }
    
    func profileView(req: Request) throws -> EventLoopFuture<View> {
        return User.find(req.parameters.get("userId"), on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            let context = ProfileContext(firstName: user.firstName,
                                         lastName: user.lastName,
                                         email: user.email,
                                         isAdmin: user.isAdmin,
                                         baseUrl: req.baseUrl)
            return req.view.render("profile", context)
        }
    }
    
    func verifyEmailView(req: Request) throws -> EventLoopFuture<View> {
        return Token.find(req.parameters.get("tokenId"), on: req.db).flatMap { token in
            guard let token = token, token.source == .emailVerification, token.isValid else {
                return req.fail(CustomAbort.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
                user.isEmailVerified = true
                return user.save(on: req.db).flatMap {
                    return req.view.render("email-verified")
                }
            }
        }
    }
    
    func passwordResetView(req: Request) throws -> EventLoopFuture<View> {
        return Token.find(req.parameters.get("tokenId"), on: req.db).flatMap { token in
            guard let token = token, let tokenId = token.id, token.source.isValidForPasswordReset, token.isValid else {
                return req.fail(CustomAbort.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard user != nil else { return req.fail(CustomAbort.userDoesNotExist) }
                let resetPasswordUrl = "\(req.baseUrl)/auth/resetPassword/\(tokenId)"
                return req.view.render("password-reset", ResetPasswordContext(baseUrl: req.baseUrl,
                                                                              resetPasswordUrl: resetPasswordUrl))
            }
        }
    }

}
