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
            request.headers.add(name: "Device-ID", value: "1")
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
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let session = try response.content.decode(NewSession.self)
            XCTAssertNotNil(session.token)
            registrationSession = session
            XCTAssertEqual(session.user?.firstName, validUser.firstName)
        })
        try app.test(.DELETE, "auth/logout", beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.DELETE, "auth/logout", headers: registrationSession.bearerHeaders, beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.POST, "auth/login", beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: invalidEmailHeaders, beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: wrongPasswordHeaders, beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: validHeaders, beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
            let session = try response.content.decode(NewSession.self)
            XCTAssertNotNil(session.token)
            XCTAssertNotEqual(session.token, registrationSession.token)
            XCTAssertEqual(session.user?.firstName, validUser.firstName)
        })
    }
    
    func testPasswordReset() throws {
        try app.test(.POST, "auth/login", beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .unauthorized)
        })
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: "michael-jordan@gmail.com", password: "123456"), beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        var passwordResetTokenId: String?
        let newPassword = "1234567"
        try app.test(.POST, "auth/sendPasswordResetEmail", beforeRequest: { request in
            try request.content.encode(PasswordReset(email: "michael-jordan@gmail.com", frontendBaseUrl: "url"))
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            passwordResetTokenId = try response.content.decode(String.self)
        })
        guard let tokenId = passwordResetTokenId else { fatalError() }
        try app.test(.PUT, "auth/resetPassword/\(tokenId)", beforeRequest: { request in
            try request.content.encode(NewPassword(value: newPassword))
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
        try app.test(.POST, "auth/login", headers: NewSession.basicHeaders(email: "michael-jordan@gmail.com", password: newPassword), beforeRequest: { request in
            request.headers.add(name: "Device-ID", value: "1")
        }, afterResponse: { response in
            XCTAssertEqual(response.status, .ok)
        })
    }
    
    func testEmailContext() {
        let user = User(firstName: "Test",
                        lastName: "User",
                        username: "test-user",
                        email: "test-user@gmail.com",
                        passwordHash: "hash")
        
        let passwordResetContext = EmailContext(user: user, url: "www.google.com", leafTemplate: .passwordResetEmail)
        XCTAssertEqual(passwordResetContext.name, "Test")
        XCTAssertEqual(passwordResetContext.subject, "Password Reset")
        let passwordResetMessage = passwordResetContext.message(from: View(data: ByteBuffer()), to: user)
        XCTAssertEqual(passwordResetMessage.from, Environment.mailgunFrom)
        XCTAssertEqual(passwordResetMessage.to, user.email)
                
        let verifyEmailContext = EmailContext(user: user, url: "www.yahoo.com", leafTemplate: .verifyEmailEmail)
        XCTAssertEqual(verifyEmailContext.name, "Test")
        XCTAssertEqual(verifyEmailContext.subject, "Please verify your email")
        let verifyEmailMessage = passwordResetContext.message(from: View(data: ByteBuffer()), to: user)
        XCTAssertEqual(verifyEmailMessage.from, Environment.mailgunFrom)
        XCTAssertEqual(verifyEmailMessage.to, user.email)
    }
}
