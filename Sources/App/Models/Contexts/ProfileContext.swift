//
//  ProfileContext.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation

struct ProfileContext: Codable {
    let firstName: String
    let lastName: String
    let email: String
    let isAdmin: Bool
}
