//
//  AuthControllerWithEmailVerificationTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/7/21.
//

@testable import App
import XCTest
import XCTVapor

class AuthControllerWithEmailVerificationTests: XCTestCase {
    var app: Application!
    let validUser = UserData(firstName: "Steve",
                             lastName: "Kerr",
                             username: "steve-kerr",
                             email: "steve-kerr@gmail.com",
                             password: "123456")

    override func setUpWithError() throws {
        app = try Application.testable(requireEmailVerification: true)
    }

    override func tearDownWithError() throws {
        app.shutdown()
    }

    func testRegisterLogoutAndLogin() throws {
        try app.test(.POST, "auth/register", beforeRequest: { request in
            try request.content.encode(validUser)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: validUser.email, password: validUser.password), afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
    }
}
