//
//  DB.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Foundation
import Vapor

enum DB {
    case dev
    case test
    
    var username: String {
        return "postgres"
    }
    
    var password: String {
        return ""
    }
    
    var host: String {
        return "localhost"
    }
    
    var port: String {
        switch self {
        case .dev: return "5432"
        case .test: return "5433"
        }
    }
    
    var database: String {
        return "vapor_base"
    }
    
    var url: String {
        return "postgres://\(username):\(password)@\(host):\(port)/\(database)"
    }
    
    static func url(for env: Environment) -> String {
        switch env {
        case .production: return Environment.databaseUrl
        case .testing: return DB.test.url
        case .development: return DB.dev.url
        default:
            print("Invalid Environment")
            fatalError()
        }
    }
}
