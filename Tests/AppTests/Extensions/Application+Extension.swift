//
//  Application+Extension.swift
//  App
//
//  Created by Adam Zarn on 7/4/21.
//

import App
import XCTVapor

extension Application {
  static func testable() throws -> Application {
    let app = Application(.testing)
    try configure(app)
    
    try app.autoRevert().wait()
    try app.autoMigrate().wait()

    return app
  }
}
