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
        viewRoute.get("welcome", use: welcomeView)
        viewRoute.get("home", use: homeView)
        viewRoute.get("register", use: registerView)
        viewRoute.get("login", use: loginView)
        viewRoute.get("profile", ":userId", use: profileView)
        viewRoute.get("verifyEmail", ":tokenId", use: verifyEmailView)
        viewRoute.get("passwordReset", ":tokenId", use: passwordResetView)
        
    }
    
    func welcomeView(req: Request) -> EventLoopFuture<View> {
        return req.view.render("welcome")
    }
    
    func homeView(req: Request) -> EventLoopFuture<View> {
        return User.query(on: req.db).all().flatMap { users in
            let publicUsers = users.compactMap { try? $0.asPublic() }
            return req.view.render("home", HomeContext(users: publicUsers))
        }
    }
    
    func registerView(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("register")
    }
    
    func loginView(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("login")
    }
    
    func profileView(req: Request) throws -> EventLoopFuture<View> {
        return User.find(req.parameters.get("userId"), on: req.db).flatMap { user in
            guard let user = user else { return req.fail(CustomAbort.userDoesNotExist) }
            let context = ProfileContext(firstName: user.firstName,
                                         lastName: user.lastName,
                                         email: user.email,
                                         isAdmin: user.isAdmin)
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
                return req.view.render("password-reset", ResetPasswordContext(tokenId: "\(tokenId)"))
            }
        }
    }

}
