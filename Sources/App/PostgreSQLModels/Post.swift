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
    
    struct Public: Content {
        let id: UUID
        let userId: UUID?
        let text: String
        let createdAt: Date?
    }
    
    func asPublic() throws -> Post.Public {
        return Public(id: try requireID(),
                      userId: $user.id,
                      text: text,
                      createdAt: createdAt)
    }
}
