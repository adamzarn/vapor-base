//
//  AuthControllerTests.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import XCTest
import XCTVapor

class AuthControllerTests: XCTestCase {
    var app: Application!
    var testUserSessions: TestUserSessions!
    let userMissingLastName = UserData(firstName: "Steve",
                                       lastName: "",
                                       username: "steve-kerr",
                                       email: "steve-kerr@gmail.com",
                                       password: "123456")
    let userWithInvalidPassword = UserData(firstName: "Steve",
                                           lastName: "Kerr",
                                           username: "steve-kerr",
                                           email: "steve-kerr@gmail.com",
                                           password: "12345")
    let validUser = UserData(firstName: "Steve",
                             lastName: "Kerr",
                             username: "steve-kerr",
                             email: "steve-kerr@gmail.com",
                             password: "123456")
    let invalidEmailHeaders = NewSession.basicHeaders(email: "steve-kerr@gmal.com", password: "123456")
    let wrongPasswordHeaders = NewSession.basicHeaders(email: "steve-kerr@gmail.com", password: "1234567")
    let validHeaders = NewSession.basicHeaders(email: "steve-kerr@gmail.com", password: "123456")
    
    override func setUpWithError() throws {
        app = try Application.testable()
        testUserSessions = try TestUserSessions(database: app.db, verifiedEmailIndices: [])
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    func testRegisterLogoutAndLogin() throws {
        var registrationSession: NewSession!
        try app.test(.POST, "auth/register", beforeRequest: { request in
            try request.content.encode(userMissingLastName)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.POST, "auth/register", beforeRequest: { request in
            try request.content.encode(userWithInvalidPassword)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .badRequest)
        })
        try app.test(.POST, "auth/register", beforeRequest: { request in
            try request.content.encode(validUser)
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let session = try response.content.decode(NewSession.self)
            XCTAssertNotNil(session.token)
            registrationSession = session
            XCTAssertEqual(session.user?.firstName, validUser.firstName)
        })
        try app.test(.DELETE, "auth/logout", headers: registrationSession.bearerHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.POST, "auth/login", headers: invalidEmailHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: wrongPasswordHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: validHeaders, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let session = try response.content.decode(NewSession.self)
            XCTAssertNotNil(session.token)
            XCTAssertNotEqual(session.token, registrationSession.token)
            XCTAssertEqual(session.user?.firstName, validUser.firstName)
        })
    }
    
    func testEmailVerification() throws {
        var emailVerificationTokenId: String?
        try app.test(.POST, "auth/sendEmailVerificationEmail", headers: NewSession.basicHeaders(email: "michael-jordan@gmail.com", password: "123456"), afterResponse: { response in
            emailVerificationTokenId = try response.content.decode(String.self)
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.GET, "users", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let user = try response.content.decode(User.Public.self)
            XCTAssertFalse(user.isEmailVerified)
        })
        guard let tokenId = emailVerificationTokenId else { fatalError() }
        try app.test(.PUT, "auth/verifyEmail/\(tokenId)")
        try app.test(.GET, "users", headers: testUserSessions.michaelJordan.bearerHeaders, afterResponse: { response in
            let user = try response.content.decode(User.Public.self)
            XCTAssertTrue(user.isEmailVerified)
        })
    }
    
    func testPasswordReset() throws {
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: "michael-jordan@gmail.com", password: "123456"), afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        var passwordResetTokenId: String?
        let newPassword = "1234567"
        try app.test(.POST, "auth/sendPasswordResetEmail", beforeRequest: { request in
            try request.content.encode(PasswordReset(email: "michael-jordan@gmail.com", url: nil))
        }, afterResponse: { response in
            passwordResetTokenId = try response.content.decode(String.self)
        })
        guard let tokenId = passwordResetTokenId else { fatalError() }
        try app.test(.PUT, "auth/resetPassword/\(tokenId)", beforeRequest: { request in
            try request.content.encode(NewPassword(value: newPassword))
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: "michael-jordan@gmail.com", password: newPassword), afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
    }
}
