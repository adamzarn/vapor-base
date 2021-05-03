//
//  EmailVerificationEmailContext.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation

struct EmailVerificationEmailContext: Codable {
    let name: String?
    let verifyEmailUrl: String
}
