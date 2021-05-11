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
        viewRoute.get("verifyEmail", ":tokenId", use: emailVerificationResultView)
        viewRoute.get("passwordReset", ":tokenId", use: passwordResetView)
        
    }
    
    func welcomeView(req: Request) -> EventLoopFuture<View> {
        return req.leaf.render(LeafTemplate.welcome.rawValue)
    }
    
    func homeView(req: Request) -> EventLoopFuture<View> {
        return User.query(on: req.db).all().flatMap {
            let users = $0.compactMap { try? $0.asPublic() }.sorted(by: { ($0.lastName ?? "") < ($1.lastName ?? "") })
            return req.leaf.render(LeafTemplate.home.rawValue, HomeContext(users: users))
        }
    }
    
    func registerView(req: Request) throws -> EventLoopFuture<View> {
        return req.leaf.render(LeafTemplate.register.rawValue)
    }
    
    func loginView(req: Request) throws -> EventLoopFuture<View> {
        return req.leaf.render(LeafTemplate.login.rawValue)
    }
    
    func profileView(req: Request) throws -> EventLoopFuture<View> {
        return User.find(req.parameters.get("userId"), on: req.db).flatMap { user in
            guard let user = user else { return req.fail(Exception.userDoesNotExist) }
            return user.$followers.query(on: req.db).all().flatMap { followers in
                return user.$following.query(on: req.db).all().flatMap { following in
                    let context = ProfileContext(user: user,
                                                 followers: followers,
                                                 following: following,
                                                 followerIds: followers.compactMap { $0.id?.uuidString })
                    return req.leaf.render(LeafTemplate.profile.rawValue, context)
                }
            }
        }
    }
    
    func emailVerificationResultView(req: Request) throws -> EventLoopFuture<View> {
        var context = EmailVerificationResultContext(message: "")
        return Token.find(req.parameters.get("tokenId"), on: req.db).flatMap { token in
            guard let token = token, token.source == .emailVerification, token.isValid else {
                context.message = Exception.invalidToken.reason
                return req.leaf.render(LeafTemplate.emailVerificationResult.rawValue, context)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard let user = user else {
                    context.message = Exception.userDoesNotExist.reason
                    return req.leaf.render(LeafTemplate.emailVerificationResult.rawValue, context)
                }
                user.isEmailVerified = true
                return user.save(on: req.db).flatMap {
                    context.message = "Your email was successfully verified."
                    return req.leaf.render(LeafTemplate.emailVerificationResult.rawValue, context)
                }
            }
        }
    }
    
    func passwordResetView(req: Request) throws -> EventLoopFuture<View> {
        return Token.find(req.parameters.get("tokenId"), on: req.db).flatMap { token in
            guard let token = token, let tokenId = token.id, token.source.isValidForPasswordReset, token.isValid else {
                return req.fail(Exception.invalidToken)
            }
            return User.find(token.$user.id, on: req.db).flatMap { user in
                guard user != nil else { return req.fail(Exception.userDoesNotExist) }
                return req.leaf.render(LeafTemplate.passwordReset.rawValue, ResetPasswordContext(tokenId: "\(tokenId)"))
            }
        }
    }

}
