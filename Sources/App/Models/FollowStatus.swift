//
//  FollowStatus.swift
//  
//
//  Created by Adam Zarn on 9/7/21.
//

import Foundation
import Vapor

struct FollowStatus: Content {
    let loggedInUserIsFollowingOtherUser: Bool
    let otherUserIsFollowingLoggedInUser: Bool
}
