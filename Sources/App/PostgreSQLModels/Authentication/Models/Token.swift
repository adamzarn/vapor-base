//
//  Token.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

final class Token: Model, Content {

    init() {}
    static let schema = "Tokens"
    static let pathComponent: PathComponent = "tokens"
  
    @ID(key: .id) var id: UUID?
    @Field(key: .value) var value: String
    @Field(key: .source) var source: SessionSource
    @Field(key: .expiresAt) var expiresAt: Date?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Parent(key: .userId) var user: User
  
    init(id: Token.IDValue? = nil,
         userId: User.IDValue,
         token: String,
         source: SessionSource,
         expiresAt: Date?) {
        self.id = id
        self.$user.id = userId
        self.value = token
        self.source = source
        self.expiresAt = expiresAt
    }
    
}

extension Token: ModelTokenAuthenticatable {

    static var valueKey: KeyPath<Token, Field<String>> {
        return \Token.$value
    }
    
    static var userKey: KeyPath<Token, Parent<User>> {
        return \Token.$user
    }
    
    var isValid: Bool {
        guard let expiresAt = expiresAt else { return true }
        return expiresAt > Date()
    }

}
