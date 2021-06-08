//
//  FieldKeys.swift
//  App
//
//  Created by Adam Zarn on 6/16/20.
//

import Foundation
import Fluent

extension FieldKey {
    
    static var firstName: Self { "firstName" }
    static var lastName: Self { "lastName" }
    static var username: Self { "username" }
    static var userId: Self { "userId" }
    static var value: Self { "value" }
    static var source: Self { "source" }
    static var createdAt: Self { "createdAt" }
    static var updatedAt: Self { "updatedAt" }
    static var expiresAt: Self { "expiresAt" }
    static var email: Self { "email" }
    static var passwordHash: Self { "passwordHash" }
    static var isAdmin: Self { "isAdmin" }
    static var isEmailVerified: Self { "isEmailVerified" }
    static var followingId: Self { "followingId" }
    static var followerId: Self { "followerId" }
    static var profilePhotoUrl: Self { "profilePhotoUrl" }
    static var text: Self { "text" }
    
}
