//
//  DatabaseQuery+Filter+Method+Extension.swift
//  App
//
//  Created by Adam Zarn on 5/9/21.
//

import Foundation
import Fluent

extension DatabaseQuery.Filter.Method {
    public static var caseInsensitiveContains: DatabaseQuery.Filter.Method {
        return .custom("ilike")
    }
}
