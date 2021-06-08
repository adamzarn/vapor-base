//
//  CreatePosts.swift
//  App
//
//  Created by Adam Zarn on 6/7/21.
//

import Foundation
import Fluent

struct CreatePosts: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Post.schema)
            .id()
            .field(.userId, .uuid, .references(User.schema, .id), .required)
            .field(.text, .string, .required)
            .field(.createdAt, .datetime, .required)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(Post.schema).delete()
    }
    
}
