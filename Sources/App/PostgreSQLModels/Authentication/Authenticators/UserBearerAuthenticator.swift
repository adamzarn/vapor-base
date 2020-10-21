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
        Token.query(on: request.db).with(\.$user).filter(\.$value == bearer.token).group(.or) { group in
            group.filter(\.$source == .registration).filter(\.$source == .login)
        }.first().map { token in
            do {
                guard let token = token else { throw CustomAbort.invalidToken }
                let user = token.user
                guard self.adminsOnly else { request.auth.login(user); return }
                if user.isAdmin { request.auth.login(user) }
            } catch {
            }
        }
    }

}
