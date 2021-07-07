//
//  TestUserSessions.swift
//  AppTests
//
//  Created by Adam Zarn on 7/6/21.
//

@testable import App
import Vapor
import Fluent

struct TestUserSessions {
    var sessions: [NewSession] = []
    var michaelJordan: NewSession { return sessions[0] }
    var scottiePippen: NewSession { return sessions[1] }
    var dennisRodman: NewSession { return sessions[2] }
    
    init(database: Database, adminIndices: [Int] = [], verifiedEmailIndices: [Int] = []) throws {
        let names = [("Michael", "Jordan"), ("Scottie", "Pippen"), ("Dennis", "Rodman")]
        for (index, name) in names.enumerated() {
            let session = try User.Public.testRegister(firstName: name.0,
                                                       lastName: name.1,
                                                       isAdmin: adminIndices.contains(index),
                                                       isEmailVerified: verifiedEmailIndices.contains(index),
                                                       on: database)
            sessions.append(session)
        }
    }
}

extension NewSession {
    var bearerHeaders: HTTPHeaders {
        guard let token = token else { return HTTPHeaders() }
        return HTTPHeaders([("Authorization", "Bearer \(token)")])
    }
    
    static func basicHeaders(email: String, password: String) -> HTTPHeaders {
        let string = String(format: "%@:%@", email, password)
        let stringData = string.data(using: String.Encoding.utf8)!
        let base64String = stringData.base64EncodedString()
        return HTTPHeaders([("Authorization", "Basic \(base64String)")])
    }
}
