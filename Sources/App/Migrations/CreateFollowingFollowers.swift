//
//  CreateFollowingFollowers.swift
//  App
//
//  Created by Adam Zarn on 9/27/20.
//

import Foundation
import Fluent

struct CreateFollowingFollowers: Migration {
    
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(FollowingFollower.schema)
            .id()
            .field(.followingId, .uuid, .required, .references(User.schema, .id))
            .field(.followerId, .uuid, .required, .references(User.schema, .id))
            .ignoreExisting()
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.schema(FollowingFollower.schema).delete()
    }
    
}
