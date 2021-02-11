//
//  UserStatus.swift
//  App
//
//  Created by Adam Zarn on 1/9/21.
//

import Foundation
import Vapor

struct UserStatus: Content {
    let email: String
    let exists: Bool
}
