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
        Token.query(on: request.db).with(\.$user).filter(\.$value == bearer.token).first().map {
            if let token = $0 {
                let user = token.user
                guard self.adminsOnly else { request.auth.login(user); return }
                if user.isAdmin { request.auth.login(user) }
            }
        }
    }

}
