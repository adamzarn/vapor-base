//
//  SessionSource.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

enum SessionSource: Int, Content {
    case signup
    case login
    
    var pathComponent: PathComponent {
        switch self {
        case .signup: return "signup"
        case .login: return "login"
        }
    }
    
}
