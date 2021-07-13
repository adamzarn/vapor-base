//
//  PostgreSQLDatabaseURLComponentsTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/13/21.
//

@testable import App
import XCTest
import XCTVapor

class PostgreSQLDatabaseURLComponentsTests: XCTestCase {
    func testDBConfiguration() {
        let databaseUrl = "postgres://abc:123@host.compute.amazonaws.com:5432/xyz"
        let components = PostgreSQLDatabaseURLComponents(url: databaseUrl)
        XCTAssertEqual(components?.username, "abc")
        XCTAssertEqual(components?.password, "123")
        XCTAssertEqual(components?.hostname, "host.compute.amazonaws.com")
        XCTAssertEqual(components?.port, 5432)
        XCTAssertEqual(components?.database, "xyz")
    }
}

