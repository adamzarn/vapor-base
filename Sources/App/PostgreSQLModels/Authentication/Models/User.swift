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
    @Field(key: .firstName) var firstName: String?
    @Field(key: .lastName) var lastName: String?
    @Field(key: .username) var username: String?
    @Field(key: .email) var email: String
    @Field(key: .passwordHash) var passwordHash: String
    @Field(key: .isAdmin) var isAdmin: Bool
    @Field(key: .isEmailVerified) var isEmailVerified: Bool
    @Field(key: .profilePhotoUrl) var profilePhotoUrl: String?
    @Timestamp(key: .updatedAt, on: .update) var updatedAt: Date?
    @Timestamp(key: .createdAt, on: .create) var createdAt: Date?
    
    @Siblings(through: FollowingFollower.self, from: \.$following, to: \.$follower) var followers: [User]
    @Siblings(through: FollowingFollower.self, from: \.$follower, to: \.$following) var following: [User]
    
    @Children(for: \.$user)
    var posts: [Post]

    init(id: User.IDValue? = nil,
         firstName: String?,
         lastName: String?,
         username: String?,
         email: String,
         passwordHash: String,
         isAdmin: Bool = false,
         isEmailVerified: Bool = Settings().requireEmailVerification ? false : true,
         profilePhotoUrl: String? = nil) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.passwordHash = passwordHash
        self.isAdmin = isAdmin
        self.isEmailVerified = isEmailVerified
        self.profilePhotoUrl = profilePhotoUrl
    }
    
    static func from(data: UserData) throws -> User {
        return User(firstName: data.firstName?.trimmingCharacters(in: .whitespacesAndNewlines),
                    lastName: data.lastName?.trimmingCharacters(in: .whitespacesAndNewlines),
                    username: data.username?.trimmingCharacters(in: .whitespacesAndNewlines),
                    email: data.email,
                    passwordHash: try Bcrypt.hash(data.password))
    }
    
    func createToken(source: SessionSource) throws -> Token {
        let calendar = Calendar(identifier: .gregorian)
        let expiryDate = calendar.date(byAdding: source.tokenExpiry.component,
                                       value: source.tokenExpiry.value,
                                       to: Date())
        return try Token(userId: requireID(),
                         token: [UInt8].random(count: 16).base64,
                         source: source,
                         expiresAt: expiryDate)
    }
    
    func createPost(from data: NewPost) throws -> Post {
        return try Post(userId: try requireID(),
                        text: data.text)
    }
    
    struct Public: Content {
        let id: UUID
        let firstName: String?
        let lastName: String?
        let username: String?
        let email: String
        let updatedAt: Date?
        let createdAt: Date?
        let isAdmin: Bool
        let isEmailVerified: Bool
        let profilePhotoUrl: String?
    }
    
    func asPublic() throws -> Public {
        return Public(id: try requireID(),
                      firstName: firstName,
                      lastName: lastName,
                      username: username,
                      email: email,
                      updatedAt: updatedAt,
                      createdAt: createdAt,
                      isAdmin: isAdmin,
                      isEmailVerified: isEmailVerified,
                      profilePhotoUrl: profilePhotoUrl)
    }
}

struct UserData: Content, Validatable {
    let firstName: String?
    let lastName: String?
    let username: String?
    let email: String
    let password: String
    let frontendBaseUrl: String?
    
    init(firstName: String? = nil,
         lastName: String? = nil,
         username: String? = nil,
         email: String,
         password: String,
         frontendBaseUrl: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.password = password
        self.frontendBaseUrl = frontendBaseUrl
    }
    
    static func validations(_ validations: inout Validations) {
        validations.add("firstName", as: String.self, is: !.empty)
        validations.add("lastName", as: String.self, is: !.empty)
        validations.add("username", as: String.self, is: !.empty)
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
