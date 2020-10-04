//
//  FollowingFollower.swift
//  App
//
//  Created by Adam Zarn on 9/27/20.
//

import Foundation
import Vapor
import Fluent

final class FollowingFollower: Model {
    
    init() {}
    static let schema = "FollowingFollower"

    @ID(key: .id) var id: UUID?
    @Parent(key: .followingId) var following: User
    @Parent(key: .followerId) var follower: User
    
    init(id: UUID? = nil, following: User, follower: User) throws {
        self.id = id
        self.following.id = try following.requireID()
        self.follower.id = try follower.requireID()
    }
    
}
