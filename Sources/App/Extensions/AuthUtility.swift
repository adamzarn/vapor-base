//
//  AuthUtility.swift
//  App
//
//  Created by Adam Zarn on 5/11/21.
//

import Foundation
import Vapor

class AuthUtility {
    class func getAuthorizedUser(req: Request, mustBeAdmin: Bool = false) throws -> User {
        do {
            let user = try req.auth.require(User.self)
            if Settings.requireEmailVerification && user.isEmailVerified == false {
                throw Exception.emailIsNotVerified
            }
            if user.isAdmin == false && mustBeAdmin {
                throw Exception.userIsNotAdmin
            }
            return user
        }
    }
    
    class func getFailedFuture<T>(for error: Error, req: Request) -> EventLoopFuture<T> {
        if let abort = error as? Abort {
            return req.fail(abort)
        } else if let exception = error as? Exception {
            return req.fail(exception)
        } else {
            return req.fail(Exception.unknown)
        }
    }
}
