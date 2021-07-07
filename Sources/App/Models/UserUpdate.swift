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
    let isAdmin: Bool?
    let frontendBaseUrl: String?
    
    init(firstName: String? = nil,
         lastName: String? = nil,
         username: String? = nil,
         email: String? = nil,
         isAdmin: Bool? = nil,
         frontendBaseUrl: String? = nil) {
        self.firstName = firstName
        self.lastName = lastName
        self.username = username
        self.email = email
        self.isAdmin = isAdmin
        self.frontendBaseUrl = frontendBaseUrl
    }
}
