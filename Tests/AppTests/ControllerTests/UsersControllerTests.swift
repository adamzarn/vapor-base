//
//  UsersControllerTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import XCTest
import XCTVapor
import Fluent

class UsersControllerTests: XCTestCase {
    var app: Application!
    
    var testUserSessions: TestUserSessions!
    
    override func setUpWithError() throws {
        app = try Application.testable()
        testUserSessions = try TestUserSessions(database: app.db, adminIndices: [0])
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testGetUser() throws {
        try app.test(.GET, "users", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.GET, "users", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let user = try response.content.decode(User.Public.self)
            XCTAssertEqual(user.id, testUserSessions.michaelJordan.user?.id)
        })
        if let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString {
            try app.test(.GET, "users/\(scottiePippenId)", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
                let user = try response.content.decode(User.Public.self)
                XCTAssertEqual(user.id, testUserSessions.scottiePippen.user?.id)
            })
        }
    }
    
    func testGetUserStatusWithEmail() throws {
        try app.test(.GET, "users/status?email=michael-jordan@gmail.com", afterResponse: { response in
            let status = try response.content.decode(UserStatus.self)
            XCTAssertTrue(status.exists)
        })
        try app.test(.GET, "users/status?email=charles-barkley@gmail.com", afterResponse: { response in
            let status = try response.content.decode(UserStatus.self)
            XCTAssertFalse(status.exists)
        })
        try app.test(.GET, "users/status", afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
    }
    
    func testUserSearch() throws {
        try testUserSearch(query: "", expectedCount: 3)
        try testUserSearch(query: "query=a", expectedCount: 3)
        try testUserSearch(query: "query=an", expectedCount: 2)
        try testUserSearch(query: "query=jordan", expectedCount: 1)
        try testUserSearch(query: "query=nothing", expectedCount: 0)
        try testUserSearch(query: "isAdmin=yes", expectedCount: 1)
        try testUserSearch(query: "excludeMe=yes", expectedCount: 2)
        try testUserSearch(query: "start=0&end=1", expectedCount: 1)
        
        try testUserSearch(query: "isFollowing=yes", expectedCount: 0)
        if let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString {
            try app.test(.POST, "users/\(scottiePippenId)/follow", headers: testUserSessions.michaelJordan.bearerHeaders)
        }
        try testUserSearch(query: "isFollowing=yes", expectedCount: 1)
        
        try testUserSearch(query: "isFollower=yes", expectedCount: 0)
        if let michaelJordanId = testUserSessions.michaelJordan.user?.id.uuidString {
            try app.test(.POST, "users/\(michaelJordanId)/follow", headers: testUserSessions.scottiePippen.bearerHeaders)
        }
        try testUserSearch(query: "isFollower=yes", expectedCount: 1)
    }
    
    private func testUserSearch(query: String, expectedCount: Int) throws {
        try app.test(.GET, "users/search?\(query)", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, expectedCount)
        })
    }
    
    func testFollowUnfollowFollowersFollowing() throws {
        guard let michaelJordanId = testUserSessions.michaelJordan.user?.id.uuidString,
            let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.POST, "users/\(michaelJordanId)/follow", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.POST, "users/abc/follow", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.POST, "users/\(scottiePippenId)/follow", headers: testUserSessions.michaelJordan.bearerHeaders)
        try app.test(.GET, "users/\(scottiePippenId)/followers", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0].id, testUserSessions.michaelJordan.user?.id)
        })
        try app.test(.GET, "users/\(michaelJordanId)/following", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0].id, testUserSessions.scottiePippen.user?.id)
        })
        try app.test(.DELETE, "users/\(scottiePippenId)/unfollow", headers: testUserSessions.michaelJordan.bearerHeaders)
        try app.test(.GET, "users/\(scottiePippenId)/followers", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 0)
        })
        try app.test(.GET, "users/\(michaelJordanId)/following", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 0)
        })
    }
    
    func testDeleteSelf() throws {
        try app.test(.DELETE, "users", headers: testUserSessions.scottiePippen.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.DELETE, "users", headers: testUserSessions.dennisRodman.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try testUserSearch(query: "", expectedCount: 1)
    }
    
    func testDeleteOtherAsAdmin() throws {
        guard let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.DELETE, "users/\(scottiePippenId)", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try testUserSearch(query: "", expectedCount: 2)
    }
    
    func testDeleteFollowPostToken() throws {
        guard let michaelJordanId = testUserSessions.michaelJordan.user?.id.uuidString,
            let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.POST, "posts", headers: testUserSessions.scottiePippen.bearerHeaders, beforeRequest: { request in
            try request.content.encode(NewPost(text: "Hello"))
        })
        try app.test(.GET, "posts", headers: testUserSessions.scottiePippen.bearerHeaders, afterResponse: { response in
            let posts = try response.content.decode([Post.Public].self)
            XCTAssertEqual(posts.count, 1)
        })
        try app.test(.POST, "users/\(michaelJordanId)/follow", headers: testUserSessions.scottiePippen.bearerHeaders)
        try app.test(.POST, "users/\(scottiePippenId)/follow", headers: testUserSessions.michaelJordan.bearerHeaders)
        try app.test(.GET, "users/\(scottiePippenId)/followers", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0].id, testUserSessions.michaelJordan.user?.id)
        })
        try app.test(.GET, "users/\(michaelJordanId)/following", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 1)
            XCTAssertEqual(users[0].id, testUserSessions.scottiePippen.user?.id)
        })
        try app.test(.DELETE, "users/\(scottiePippenId)", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.GET, "posts/\(scottiePippenId)", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.GET, "users/\(scottiePippenId)/followers", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.GET, "users/\(michaelJordanId)/following", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let users = try response.content.decode([User.Public].self)
            XCTAssertEqual(users.count, 0)
        })
    }
    
    func testDeleteOtherAsUser() throws {
        guard let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.DELETE, "users/\(scottiePippenId)", headers: testUserSessions.dennisRodman.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try testUserSearch(query: "", expectedCount: 3)
    }
    
    func testUpdateSelfAsUser() throws {
        try app.test(.PUT, "users", headers: testUserSessions.scottiePippen.bearerHeaders, beforeRequest: { request in
            try request.content.encode(UserUpdate(firstName: "Scott", lastName: "Pip", username: "Robin", email: "scott-pip@gmail.com", isAdmin: true))
        }, afterResponse: { response in
            let updatedUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(updatedUser.firstName, "Scott")
            XCTAssertEqual(updatedUser.lastName, "Pip")
            XCTAssertEqual(updatedUser.username, "Robin")
            XCTAssertEqual(updatedUser.email, "scott-pip@gmail.com")
            XCTAssertEqual(updatedUser.isEmailVerified, true)
            XCTAssertEqual(updatedUser.isAdmin, false)
        })
    }
    
    func testUpdateOtherAsAdmin() throws {
        guard let scottiePippenId = testUserSessions.scottiePippen.user?.id.uuidString else { return }
        try app.test(.PUT, "users/\(scottiePippenId)", headers: testUserSessions.michaelJordan.bearerHeaders, beforeRequest: { request in
            try request.content.encode(UserUpdate(firstName: "S", lastName: "P", username: "Sidekick", email: "s-p@gmail.com", isAdmin: true))
        }, afterResponse: { response in
            let updatedUser = try response.content.decode(User.Public.self)
            XCTAssertEqual(updatedUser.firstName, "S")
            XCTAssertEqual(updatedUser.lastName, "P")
            XCTAssertEqual(updatedUser.username, "Sidekick")
            XCTAssertEqual(updatedUser.email, "s-p@gmail.com")
            XCTAssertEqual(updatedUser.isEmailVerified, true)
            XCTAssertEqual(updatedUser.isAdmin, true)
        })
    }
}
