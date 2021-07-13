//
//  PostgreSQLDatabaseURLComponents.swift
//  App
//
//  Created by Adam Zarn on 7/13/21.
//

import Foundation

struct PostgreSQLDatabaseURLComponents {
    let url: String
    let components: [String]
    
    var username: String { return components[0] }
    var password: String { return components[1] }
    var hostname: String { return components[2] }
    var port: Int { return Int(components[3])! }
    var database: String { return components[4] }
    
    init?(url: String) {
        let components = url
            .replacingOccurrences(of: "postgres://", with: "")
            .split { [":", "@", "/"].contains($0.description) }
            .map { String($0) }
        guard components.count == 5 else { return nil }
        guard Int(components[3]) != nil else { return nil }
        self.url = url
        self.components = components
    }
}
