//
//  NewFollowingStatus.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation

struct NewFollowingStatus: Codable {
    let otherUserId: UUID
    let follow: Bool
}
