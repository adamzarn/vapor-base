//
//  NewSession.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

struct NewSession: Content {
    let id: String?
    let token: String?
    var requireEmailVerification = Settings.requireEmailVerification
    let user: User.Public?
}
