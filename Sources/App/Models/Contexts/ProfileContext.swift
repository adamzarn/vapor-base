//
//  ProfileContext.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation

struct ProfileContext: Codable {
    let user: User
    let followers: [User]
    let following: [User]
}
