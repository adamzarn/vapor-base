//
//  Post.swift
//  App
//
//  Created by Adam Zarn on 6/7/21.
//

import Vapor
import Fluent

final class Post: Model, Content {
    
    init() {}
    static let schema = "Posts"
    static let pathComponent: PathComponent = "posts"

    @ID(key: .id) var id: UUID?
    @Field(key: .text) var text: String
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .userId) var user: User
    
    init(id: Post.IDValue? = nil,
         userId: User.IDValue,
         text: String) throws {
        self.id = id
        self.$user.id = userId
        self.text = text
    }
    
    func asMyPost() throws -> MyPost {
        return MyPost(id: try requireID(),
                      text: text,
                      createdAt: createdAt)
    }
}
