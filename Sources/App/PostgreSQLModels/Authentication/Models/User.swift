//
//  User.swift
//  App
//
//  Created by Adam Zarn on 6/18/20.
//

import Vapor
import Fluent

final class User: Model, Content {
    
    init() {}
    static let schema = "Users"
    static let pathComponent: PathComponent = "users"

    @ID(key: .id) var id: UUID?
    @Field(key: .firstName) var firstName: String
    @Field(key: .lastName) var lastName: String
    @Field(key: .email) var email: String
    @Field(key: .passwordHash) var passwordHash: String
    @Field(key: .isAdmin) var isAdmin: Bool
    @Timestamp(key: .updatedAt, on: .update) var updatedAt: Date?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Siblings(through: FollowingFollower.self, from: \.$following, to: \.$follower) var followers: [User]
    @Siblings(through: FollowingFollower.self, from: \.$follower, to: \.$following) var following: [User]

    init(id: User.IDValue? = nil,
         firstName: String,
         lastName: String,
         email: String,
         passwordHash: String,
         isAdmin: Bool = false) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
    }
    
    static func from(data: UserData) throws -> User {
        return User(firstName: data.firstName,
                    lastName: data.lastName,
                    email: data.email,
                    passwordHash: try Bcrypt.hash(data.password),
                    isAdmin: false)
    }
    
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: .year, value: 1, to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64,
                         source: source,
                         expiresAt: expiryDate)
    }
    
    struct Public: Content {
        let id: UUID
        let firstName: String
        let lastName: String
        let email: String
        let updatedAt: Date?
        let createdAt: Date?
        let isAdmin: Bool
    }
    
    func asPublic() throws -> Public {
        return Public(id: try requireID(),
                      firstName: firstName,
                      lastName: lastName,
                      email: email,
                      updatedAt: updatedAt,
                      createdAt: createdAt,
                      isAdmin: isAdmin)
    }
    
}

struct UserData: Content, Validatable {
    let firstName: String
    let lastName: String
    let email: String
    let password: String
    
    static func validations(_ validations: inout Validations) {
        validations.add("email", as: String.self, is: .email)
        validations.add("password", as: String.self, is: .count(6...))
    }
    
}

extension User: ModelAuthenticatable {

    static var usernameKey: KeyPath<User, Field<String>> {
        return \User.$email
    }

    static var passwordHashKey: KeyPath<User, Field<String>> {
        return \User.$passwordHash
    }

    func verify(password: String) throws -> Bool {
        return try Bcrypt.verify(password, created: self.passwordHash)
    }

}
