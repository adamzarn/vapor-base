//
//  PasswordResetEmailContext.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation

struct PasswordResetEmailContext: Codable {
    let name: String?
    let passwordResetUrl: String
}
