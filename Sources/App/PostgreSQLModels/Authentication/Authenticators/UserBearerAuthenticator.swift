//
//  UserBearerAuthenticator.swift
//  App
//
//  Created by Adam Zarn on 9/23/20.
//

import Foundation
import Vapor
import Fluent

struct UserBearerAuthenticator: BearerAuthenticator {
    
    let adminsOnly: Bool
    
    init(adminsOnly: Bool = false) {
        self.adminsOnly = adminsOnly
    }
    
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        Token.query(on: request.db)
            .with(\.$user)
            .filter(\.$value == bearer.token)
            .group(.or) { group in
                group
                    .filter(\.$source == .registration)
                    .filter(\.$source == .login)
        }.first().map { token in
            do {
                guard let token = token else { throw Exception.invalidToken }
                let user = token.user
                try checkEmailVerificationStatus(user: user, request: request)
            } catch {}
        }
    }
    
    func checkEmailVerificationStatus(user: User, request: Request) throws {
        guard Constants.requireEmailVerification else {
            try checkAdminStatus(user: user, request: request)
            return
        }
        guard user.isEmailVerified else {
            throw Exception.emailIsNotVerified
        }
        try checkAdminStatus(user: user, request: request)
    }
    
    func checkAdminStatus(user: User, request: Request) throws {
        guard adminsOnly else {
            request.auth.login(user)
            return
        }
        guard user.isAdmin else {
            throw Exception.userIsNotAdmin
        }
        request.auth.login(user)
    }

}
