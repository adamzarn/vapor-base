//
//  ErrorBody.swift
//  AppTests
//
//  Created by Adam Zarn on 7/10/21.
//

import Foundation
import Vapor

struct ErrorBody: Content {
    let error: Bool
    let reason: String
}
