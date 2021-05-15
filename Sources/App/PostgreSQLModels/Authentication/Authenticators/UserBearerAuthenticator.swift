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
    
    func authenticate(bearer: BearerAuthorization, for request: Request) -> EventLoopFuture<Void> {
        Token.query(on: request.db)
            .with(\.$user)
            .filter(\.$value == bearer.token)
            .group(.or) { group in
                group
                    .filter(\.$source == .registration)
                    .filter(\.$source == .login)
        }.first().map { token in
            guard let token = token else { return }
            let user = token.user
            request.auth.login(user)
        }
    }

}
