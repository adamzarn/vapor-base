//
//  UserUpdate.swift
//  App
//
//  Created by Adam Zarn on 5/1/21.
//

import Foundation
import Vapor

struct UserUpdate: Content {
    let firstName: String?
    let lastName: String?
    let username: String?
    let email: String?
    let frontendBaseUrl: String?
}
