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
    
    func authenticate(basic: BasicAuthorization, for request: Request) -> EventLoopFuture<Void> {
        User.query(on: request.db).filter(\.$email == basic.username).first().map { user in
            do {
                if let user = user, try Bcrypt.verify(basic.password, created: user.passwordHash) {
                    request.auth.login(user)
                }
            } catch let error {
                print(error)
            }
        }
    }

}
