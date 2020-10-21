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
    case mustBeAdminToSetFollowingStatusOfAnotherUser
    case mustBeAdminToGetFollowersOfAnotherUser
    case mustBeAdminToGetFollowingOfAnotherUser
    case mustBeAdminToDeleteAnotherUser
    case missingEmail
    case missingPassword
    case couldNotCreateToken
    case couldNotCreatePasswordHash
    
    var reason: String {
        switch self {
        case .userAlreadyExists: return "A user with same email already exists."
        case .missingUserId: return "You must provide a user id."
        case .userDoesNotExist: return "A user with the specified id does not exist."
        case .missingAdminStatus: return "You must provide an admin status."
        case .missingFollowingStatus: return "You must provide a following status."
        case .cannotFollowSelf: return "Users cannot follow/unfollow themselves."
        case .emailIsNotVerified: return "You must verify your email to be properly authenticated."
        case .invalidToken: return "The provided token is either expired or it is not associated with any user."
        case .mustBeAdminToSetFollowingStatusOfAnotherUser: return "You must be an admin to set the following status for another user."
        case .mustBeAdminToGetFollowersOfAnotherUser: return "You must be an admin to get the followers of another user."
        case .mustBeAdminToGetFollowingOfAnotherUser: return "You must be an admin to get the following of another user."
        case .mustBeAdminToDeleteAnotherUser: return "You must be an admin to delete another user."
        case .missingEmail: return "You must provide an email to reset a user's password."
        case .missingPassword: return "You must provide a new password to update a user's password."
        case .couldNotCreateToken: return "A token could not be generated."
        case .couldNotCreatePasswordHash: return "The password could not be hashed."
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
        case .emailIsNotVerified: return .forbidden
        case .invalidToken: return .unauthorized
        case .mustBeAdminToSetFollowingStatusOfAnotherUser: return .unauthorized
        case .mustBeAdminToGetFollowersOfAnotherUser: return .unauthorized
        case .mustBeAdminToGetFollowingOfAnotherUser: return .unauthorized
        case .mustBeAdminToDeleteAnotherUser: return .unauthorized
        case .missingEmail: return .badRequest
        case .missingPassword: return .badRequest
        case .couldNotCreateToken: return .internalServerError
        case .couldNotCreatePasswordHash: return .internalServerError
        }
    }
    
}
