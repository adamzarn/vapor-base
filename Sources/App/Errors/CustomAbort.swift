//
//  CustomAbort.swift
//  App
//
//  Created by Adam Zarn on 5/21/20.
//

import Foundation
import Vapor

enum CustomAbort: AbortError {
    case userAlreadyExists
    case missingUserId
    case userDoesNotExist
    case missingAdminStatus
    case missingFollowingStatus
    case cannotFollowSelf
    case emailIsNotVerified
    case invalidToken
    
    var reason: String {
        switch self {
        case .userAlreadyExists: return "A user with same email already exists."
        case .missingUserId: return "You must provide a user id."
        case .userDoesNotExist: return "A user with the specified id does not exist."
        case .missingAdminStatus: return "You must provide an admin status."
        case .missingFollowingStatus: return "You must provide a following status."
        case .cannotFollowSelf: return "Users cannot follow/unfollow themselves."
        case .emailIsNotVerified: return "You must verify your email to be properly authenticated."
        case .invalidToken: return "The provided token is not associated with any user."
        }
    }
    
    var status: HTTPResponseStatus {
        switch self {
        case .userAlreadyExists: return .forbidden
        case .missingUserId: return .badRequest
        case .userDoesNotExist: return .badRequest
        case .missingAdminStatus: return .badRequest
        case .missingFollowingStatus: return .badRequest
        case .cannotFollowSelf: return .badRequest
        case .emailIsNotVerified: return .unauthorized
        case .invalidToken: return .unauthorized
        }
    }
    
}
