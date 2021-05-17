//
//  Settings.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation
import Vapor

struct Settings: Content {
    var requireEmailVerification: Bool = false
    var searchResultLimit: Int = 50
}
