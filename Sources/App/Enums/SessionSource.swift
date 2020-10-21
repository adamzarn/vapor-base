//
//  SessionSource.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

enum SessionSource: Int, Content {
    case registration
    case login
    case emailVerification
    case passwordReset
    
    var pathComponent: PathComponent {
        switch self {
        case .registration: return "register"
        case .login: return "login"
        case .emailVerification: return "emailVerification"
        case .passwordReset: return "passwordReset"
        }
    }
    
    var tokenExpiry: Expiry {
        switch self {
        case .registration, .login: return Expiry(component: .year, value: 1)
        case .emailVerification, .passwordReset: return Expiry(component: .minute, value: 10)
        }
    }
    
    var isValidForPasswordReset: Bool {
        return [.registration, .login, .passwordReset].contains(self)
    }
    
}
