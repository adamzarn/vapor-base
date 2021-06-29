//
//  Exception.swift
//  App
//
//  Created by Adam Zarn on 5/21/20.
//

import Foundation
import Vapor

enum Exception: String, AbortError {
    case userAlreadyExists
    case missingUserId
    case invalidUserId
    case missingTokenId
    case userDoesNotExist
    case missingAdminStatus
    case missingFollowingStatus
    case cannotFollowSelf
    case emailIsNotVerified
    case userIsNotAdmin
    case invalidToken
    case missingEmail
    case missingPassword
    case couldNotCreateToken
    case couldNotCreatePasswordHash
    case missingUserUpdate
    case missingFollowType
    case invalidFollowType
    case invalidImageType
    case invalidPost
    case unknown
    
    var reason: String {
        var description = ""
        switch self {
        case .userAlreadyExists: description = "A user with same email already exists."
        case .missingUserId: description = "You must provide a user id."
        case .invalidUserId: description = "You must provide a valid user id."
        case .missingTokenId: description = "You must provide a token id."
        case .userDoesNotExist: description = "A user with the specified id does not exist."
        case .missingAdminStatus: description = "You must provide an admin status."
        case .missingFollowingStatus: description = "You must provide a following status."
        case .cannotFollowSelf: description = "Users cannot follow/unfollow themselves."
        case .emailIsNotVerified: description = "Email verification is required."
        case .userIsNotAdmin: description = "User must be an admin to access or modify this resource."
        case .invalidToken: description = "The provided token is either expired or it is not associated with any user."
        case .missingEmail: description = "You must provide an email to reset a user's password."
        case .missingPassword: description = "You must provide a new password to update a user's password."
        case .couldNotCreateToken: description = "A token could not be generated."
        case .couldNotCreatePasswordHash: description = "The password could not be hashed."
        case .missingUserUpdate: description = "You must provide a valid user update object."
        case .missingFollowType: description = "You must provide a follow type of followers or following"
        case .invalidFollowType: description = "You must provide a follow type of followers or following"
        case .invalidImageType: description = "Images must have one of the following extensions: \(Settings().allowedImageTypes)"
        case .invalidPost: description = "You must provide a valid post object."
        case .unknown: description = "An unknown exception occurred."
        }
        return "\(rawValue): \(description)"
    }
    
    var status: HTTPResponseStatus {
        switch self {
        case .userAlreadyExists: return .forbidden
        case .missingUserId: return .badRequest
        case .invalidUserId: return .badRequest
        case .missingTokenId: return .badRequest
        case .userDoesNotExist: return .badRequest
        case .missingAdminStatus: return .badRequest
        case .missingFollowingStatus: return .badRequest
        case .cannotFollowSelf: return .badRequest
        case .emailIsNotVerified: return .unauthorized
        case .userIsNotAdmin: return .unauthorized
        case .invalidToken: return .unauthorized
        case .missingEmail: return .badRequest
        case .missingPassword: return .badRequest
        case .couldNotCreateToken: return .internalServerError
        case .couldNotCreatePasswordHash: return .internalServerError
        case .missingUserUpdate: return .badRequest
        case .missingFollowType: return .badRequest
        case .invalidFollowType: return .badRequest
        case .invalidImageType: return .badRequest
        case .invalidPost: return .badRequest
        case .unknown: return .internalServerError
        }
    }
}
