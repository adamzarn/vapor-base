//
//  PasswordReset.swift
//  App
//
//  Created by Adam Zarn on 4/27/21.
//

import Foundation
import Vapor

struct PasswordReset: Content {
    let email: String
    let frontendBaseUrl: String
}
