//
//  NewSession.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

struct NewSession: Content {
    let token: String
    let user: User.Public?
}
