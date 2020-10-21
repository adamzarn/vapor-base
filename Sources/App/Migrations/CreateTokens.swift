//
//  CreateTokens.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Foundation
import Fluent

struct CreateTokens: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Token.schema)
            .id()
            .field(.userId, .uuid, .references(User.schema, .id))
            .field(.value, .string, .required).unique(on: .value)
            .field(.source, .int, .required)
            .field(.createdAt, .datetime, .required)
            .field(.expiresAt, .datetime)
            .ignoreExisting()
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Token.schema).delete()
    }
    
}
