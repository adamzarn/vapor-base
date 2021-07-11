//
//  Settings.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation
import Vapor

struct Settings {
    static var requireEmailVerification: Bool = false
    static var searchResultLimit: Int = 50
    static var allowedImageTypes: [String] = ["png", "jpeg", "jpg", "gif"]
    static var maxBodySizeInBytes: Int = 5*1_048_576
    
    static var current: CurrentSettings {
        return CurrentSettings(emailVerificationIsRequired: Settings.requireEmailVerification,
                               searchResultLimit: Settings.searchResultLimit,
                               allowedImageTypes: Settings.allowedImageTypes,
                               maxBodySizeInBytes: Settings.maxBodySizeInBytes)
    }
}

struct CurrentSettings: Content {
    let emailVerificationIsRequired: Bool
    let searchResultLimit: Int
    let allowedImageTypes: [String]
    let maxBodySizeInBytes: Int
}

