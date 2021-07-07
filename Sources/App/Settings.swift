//
//  Settings.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation
import Vapor

struct Configuration {
    static var requireEmailVerification: Bool = false
    static var searchResultLimit: Int = 50
    static var allowedImageTypes: [String] = ["png", "jpeg", "jpg", "gif"]
    static var maxBodySizeInBytes: Int = 5*1_048_576
}

struct Settings: Content {
    var requireEmailVerification: Bool {
        return Configuration.requireEmailVerification
    }
    var searchResultLimit: Int {
        return Configuration.searchResultLimit
    }
    var allowedImageTypes: [String] {
        return Configuration.allowedImageTypes
    }
    var maxBodySizeInBytes: Int {
        return Configuration.maxBodySizeInBytes
    }
}
