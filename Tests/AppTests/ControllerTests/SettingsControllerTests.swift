//
//  SettingsControllerTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import XCTest
import XCTVapor

class SettingsControllerTests: XCTestCase {
    var app: Application!
    
    var testUserSessions: TestUserSessions!
    
    override func setUpWithError() throws {
        app = try Application.testable()
        testUserSessions = try TestUserSessions(database: app.db)
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testGetSettings() throws {
        try app.test(.GET, "settings", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.GET, "settings", afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
}

