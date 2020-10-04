//
//  DB.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//
import Foundation

enum DB {
    case prod
    case dev
    
    var username: String {
        switch self {
        case .dev: return "adamzarn"
        case .prod: return ""
        }
    }
    
    var password: String {
        switch self {
        case .dev: return ""
        case .prod: return ""
        }
    }
    
    var host: String {
        switch self {
        case .dev: return "localhost"
        case .prod: return ""
        }
    }
    
    var port: String {
        return "5432"
    }
    
    var database: String {
        switch self {
        case .dev: return ""
        case .prod: return ""
        }
    }
    
    var url: URL {
        return URL(string: "postgres://\(username):\(password)@\(host):\(port)/\(database)")!
    }
    
}
