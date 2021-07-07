//
//  DB.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//
import Foundation

enum DB {
    case dev
    case test
    
    var username: String {
        switch self {
        case .dev: return "adamzarn"
        case .test: return "adamzarn"
        }
    }
    
    var password: String {
        switch self {
        case .dev: return ""
        case .test: return ""
        }
    }
    
    var host: String {
        switch self {
        case .dev: return "localhost"
        case .test: return "localhost"
        }
    }
    
    var port: String {
        switch self {
        case .dev: return "5432"
        case .test: return "5433"
        }
    }
    
    var database: String {
        switch self {
        case .dev: return "vapor_base_dev"
        case .test: return "vapor_base_test"
        }
    }
    
    var url: URL {
        return URL(string: "postgres://\(username):\(password)@\(host):\(port)/\(database)")!
    }
    
}
