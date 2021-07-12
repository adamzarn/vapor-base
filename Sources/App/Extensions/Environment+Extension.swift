//
//  Environment+Extension.swift
//  App
//
//  Created by Adam Zarn on 7/11/21.
//

import Foundation
import Vapor

extension Environment {
    static var mailgunApiKey: String {
        return getValue(for: "MAILGUN_API_KEY")
    }
    static var mailgunSandboxDomain: String {
        return getValue(for: "MAILGUN_SANDBOX_DOMAIN")
    }
    static var mailgunDefaultDomain: String {
        return getValue(for: "MAILGUN_DEFAULT_DOMAIN")
    }
    static var mailgunFrom: String {
        return getValue(for: "MAILGUN_FROM")
    }
    static var databaseUrl: String {
        return getValue(for: "DATABASE_URL")
    }
    
    static func getValue(for key: String) -> String {
        guard let value = get(key) else {
            print("\(key) is missing")
            fatalError()
        }
        return value
    }
}
