//
//  CreateUsers.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Foundation
import Fluent

struct CreateUsers: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema)
            .id()
            .field(.firstName, .string)
            .field(.lastName, .string)
            .field(.username, .string)
            .field(.email, .string, .required).unique(on: .email)
            .field(.passwordHash, .string, .required)
            .field(.updatedAt, .datetime, .required)
            .field(.createdAt, .datetime, .required)
            .field(.isAdmin, .bool)
            .field(.isEmailVerified, .bool)
            .field(.profilePhotoUrl, .string)
            .ignoreExisting()
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(User.schema).delete()
    }
    
}
