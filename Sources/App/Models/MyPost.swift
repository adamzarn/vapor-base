//
//  MyPost.swift
//  App
//
//  Created by Adam Zarn on 6/7/21.
//

import Foundation
import Vapor

struct MyPost: Content {
    let id: UUID
    let text: String
    let createdAt: Date?
}
