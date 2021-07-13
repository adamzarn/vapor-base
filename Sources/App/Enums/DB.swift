//
//  DB.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Foundation
import Vapor
import FluentPostgresDriver

enum DB {
    case development
    case testing
    case production
    
    var username: String {
        switch self {
        case .production: return Environment.databaseComponents().username
        default: return "postgres"
        }
    }
    
    var password: String {
        switch self {
        case .production: return Environment.databaseComponents().password
        default: return ""
        }
    }
    
    var hostname: String {
        switch self {
        case .production: return Environment.databaseComponents().hostname
        default: return "localhost"
        }
    }
    
    var port: Int {
        switch self {
        case .development: return 5432
        case .testing: return 5433
        case .production: return Environment.databaseComponents().port
        }
    }
    
    var database: String {
        switch self {
        case .production: return Environment.databaseComponents().database
        default: return "vapor_base"
        }
    }
    
    var tlsConfiguration: TLSConfiguration? {
        switch self {
        case .production: return .forClient(certificateVerification: .none)
        default: return nil
        }
    }
    
    var configuration: PostgresConfiguration {
        return PostgresConfiguration(hostname: hostname,
                                     port: port,
                                     username: username,
                                     password: password,
                                     database: database,
                                     tlsConfiguration: tlsConfiguration)
    }
}

extension Environment {
    var db: DB {
        switch self {
        case .development: return DB.development
        case .testing: return DB.testing
        case .production: return DB.production
        default: fatalError()
        }
    }
}
