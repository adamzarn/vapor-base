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
    var allowedImageTypes: [String] = ["png", "jpeg", "jpg", "gif"]
    var maxBodySizeInBytes: Int = 5*1_048_576
}

struct UserUpdateResponse: Content {
    var requireEmailVerification: Bool = Settings().requireEmailVerification
}
