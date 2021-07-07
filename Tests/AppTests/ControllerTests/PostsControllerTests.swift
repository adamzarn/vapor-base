//
//  PostsControllerTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/4/21.
//

@testable import App
import XCTest
import XCTVapor

class PostsControllerTests: XCTestCase {
    var app: Application!
    
    var testUserSessions: TestUserSessions!
    
    override func setUpWithError() throws {
        app = try Application.testable()
        testUserSessions = try TestUserSessions(database: app.db)
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testCreatePost() throws {
        try app.test(.POST, "posts", headers: testUserSessions.michaelJordan.bearerHeaders, beforeRequest: { req in
            try req.content.encode(NewPost(text: "New"))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .created)
        })
        try app.test(.POST, "posts", headers: testUserSessions.michaelJordan.bearerHeaders, beforeRequest: { req in
            try req.content.encode(NewPost(text: ""))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }
    
    func testGetPosts() throws {
        try saveTestPosts()
        try app.test(.GET, "posts", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post].self)
            XCTAssertEqual(posts.count, 1)
            XCTAssert(posts.map { $0.text }.contains("Hello"))
        })
        try app.test(.GET, "posts", headers: testUserSessions.scottiePippen.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post].self)
            XCTAssertEqual(posts.count, 1)
            XCTAssert(posts.map { $0.text }.contains("Goodbye"))
        })
        try app.test(.GET, "posts", headers: testUserSessions.dennisRodman.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post].self)
            XCTAssertEqual(posts.count, 1)
            XCTAssert(posts.map { $0.text }.contains("Test"))
        })
    }
    
    func testGetFeed() throws {
        try saveTestPosts()
        try app.test(.GET, "posts/feed", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post.Public].self)
            XCTAssertEqual(posts.count, 1)
            XCTAssert(posts.map { $0.text }.contains("Hello"))
        })
        guard let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.POST, "users/\(scottiePippenId)/follow", headers: testUserSessions.michaelJordan.bearerHeaders)
        try app.test(.GET, "posts/feed", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post.Public].self)
            XCTAssertEqual(posts.count, 2)
            XCTAssert(posts.map { $0.text }.contains("Hello"))
            XCTAssert(posts.map { $0.text }.contains("Goodbye"))
        })
    }
    
    private func saveTestPosts() throws {
        try Post.testPost(text: "Hello", user: testUserSessions.michaelJordan.user, on: app.db)
        try Post.testPost(text: "Goodbye", user: testUserSessions.scottiePippen.user, on: app.db)
        try Post.testPost(text: "Test", user: testUserSessions.dennisRodman.user, on: app.db)
    }
}
