//
//  Post+Extension.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import Vapor
import Fluent

extension Post {
    static func testPost(text: String,
                         user: User.Public?,
                         on database: Database) throws {
        let post = try Post(userId: user?.id ?? UUID(), text: text)
        try post.save(on: database).wait()
    }
}
