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
    case missingPasswordResetObject
    case missingEmailVerificationObject
    case couldNotCreateToken
    case couldNotCreatePasswordHash
    case missingUserUpdate
    case missingFollowType
    case invalidFollowType
    case invalidImageType
    case invalidPost
    case unknown
    
    var reason: String {
        return "\(rawValue): \(description)"
    }
    
    var description: String {
        switch self {
        case .userAlreadyExists: return "A user with same email already exists."
        case .missingUserId: return "You must provide a user id."
        case .invalidUserId: return "You must provide a valid user id."
        case .missingTokenId: return "You must provide a token id."
        case .userDoesNotExist: return "A user with the specified id does not exist."
        case .missingAdminStatus: return "You must provide an admin status."
        case .missingFollowingStatus: return "You must provide a following status."
        case .cannotFollowSelf: return "Users cannot follow/unfollow themselves."
        case .emailIsNotVerified: return "Email verification is required."
        case .userIsNotAdmin: return "User must be an admin to access or modify this resource."
        case .invalidToken: return "The provided token is either expired or it is not associated with any user."
        case .missingEmail: return "You must provide an email to reset a user's password."
        case .missingPassword: return "You must provide a new password to update a user's password."
        case .missingPasswordResetObject: return "You must provide an email and a frontendBaseUrl."
        case .missingEmailVerificationObject: return "You must provide an email and a frontendBaseUrl."
        case .couldNotCreateToken: return "A token could not be generated."
        case .couldNotCreatePasswordHash: return "The password could not be hashed."
        case .missingUserUpdate: return "You must provide a valid user update object."
        case .missingFollowType: return "You must provide a follow type of followers or following"
        case .invalidFollowType: return "You must provide a follow type of followers or following"
        case .invalidImageType: return "Images must have one of the following extensions: \(Settings.allowedImageTypes)"
        case .invalidPost: return "You must provide a valid post object."
        case .unknown: return "An unknown exception occurred."
        }
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
        case .missingPasswordResetObject: return .badRequest
        case .missingEmailVerificationObject: return .badRequest
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
