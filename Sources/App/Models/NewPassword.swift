//
//  NewPassword.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation
import Vapor

struct NewPassword: Content, Validatable {
    let value: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("value", as: String.self, is: .count(6...))
    }
}
