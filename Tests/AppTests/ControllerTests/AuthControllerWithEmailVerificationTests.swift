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
            let error = try response.content.decode(ErrorBody.self)
            XCTAssertEqual(error.reason, Exception.emailIsNotVerified.reason)
        })
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: validUser.email, password: validUser.password), afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
            let error = try response.content.decode(ErrorBody.self)
            XCTAssertEqual(error.reason, Exception.emailIsNotVerified.reason)
        })
        var emailVerificationTokenId: String?
        try app.test(.POST, "auth/sendEmailVerificationEmail", beforeRequest: { request in
            try request.content.encode(EmailVerification(email: validUser.email, frontendBaseUrl: "url"))
        }, afterResponse: { response in
            emailVerificationTokenId = try response.content.decode(String.self)
        })
        guard let tokenId = emailVerificationTokenId else { fatalError() }
        try app.test(.PUT, "auth/verifyEmail/\(tokenId)")
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: validUser.email, password: validUser.password), afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let session = try response.content.decode(NewSession.self)
            XCTAssertEqual(session.user?.isEmailVerified, true)
        })
    }
}
