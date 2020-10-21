//
//  UserBasicAuthenticator.swift
//  App
//
//  Created by Adam Zarn on 9/23/20.
//

import Foundation
import Vapor
import Fluent

struct UserBasicAuthenticator: BasicAuthenticator {
    
    let adminsOnly: Bool
    
    init(adminsOnly: Bool = false) {
        self.adminsOnly = adminsOnly
    }
    
    func authenticate(basic: BasicAuthorization, for request: Request) -> EventLoopFuture<Void> {
        User.query(on: request.db).filter(\.$email == basic.username).first().map { user in
            do {
                if let user = user, try Bcrypt.verify(basic.password, created: user.passwordHash) {
                    guard self.adminsOnly else { request.auth.login(user); return }
                    if user.isAdmin { request.auth.login(user) }
                }
            } catch {
            }
        }
    }

}
