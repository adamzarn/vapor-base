//
//  EmailVerification.swift
//  AppTests
//
//  Created by Adam Zarn on 7/10/21.
//

import Foundation
import Vapor

struct EmailVerification: Content {
    let email: String
    let frontendBaseUrl: String
}
