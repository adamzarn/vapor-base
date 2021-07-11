//
//  Application+Extension.swift
//  App
//
//  Created by Adam Zarn on 7/4/21.
//

@testable import App
import XCTVapor

extension Application {
    static func testable(requireEmailVerification: Bool = false) throws -> Application {
        let app = Application(.testing)
        Settings.requireEmailVerification = requireEmailVerification
        try configure(app)
        try app.autoRevert().wait()
        try app.autoMigrate().wait()
        return app
    }
}
