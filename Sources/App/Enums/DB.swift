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
    
    var url: URL {
        return URL(string: "postgres://\(username):\(password)@\(host):\(port)/\(database)")!
    }
    
}
