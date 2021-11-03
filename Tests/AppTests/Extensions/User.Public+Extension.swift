//
//  User.Public+Extension.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import Vapor
import Fluent

extension User.Public {
    static func testRegister(firstName: String,
                             lastName: String,
                             isAdmin: Bool = false,
                             isEmailVerified: Bool = true,
                             on database: Database) throws -> NewSession {
        let username = "\(firstName.lowercased())-\(lastName.lowercased())"
        let user = User(firstName: firstName,
                        lastName: lastName,
                        username: username,
                        email: "\(username)@gmail.com",
                        passwordHash: try Bcrypt.hash("123456"),
                        isAdmin: isAdmin,
                        isEmailVerified: isEmailVerified)
        try user.save(on: database).wait()
        let token = try user.createToken(deviceId: "1", source: .registration)
        try token.save(on: database).wait()
        return NewSession(id: token.id?.uuidString, token: token.value, user: try user.asPublic())
    }
}
