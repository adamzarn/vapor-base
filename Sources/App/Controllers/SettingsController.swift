//
//  SettingsController.swift
//  App
//
//  Created by Adam Zarn on 5/17/21.
//

import Foundation
import Vapor
import Fluent

class SettingsController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let settingsRoute = routes.grouped("settings")
        let tokenProtectedSettingsRoute = settingsRoute.grouped(UserBearerAuthenticator())
        
        tokenProtectedSettingsRoute.get(use: getSettings)
        
    }
    
    /// Get Settings
    ///
    /// - Possible Errors (in order of execution):
    ///     - 401 - Invalid email or password
    ///     - 401 - emailIsNotVerified - Email verification is required.
    ///
    /// - Returns: CurrentSettings
    ///
    func getSettings(req: Request) throws -> EventLoopFuture<CurrentSettings> {
        do {
            _ = try AuthUtility.getAuthorizedUser(req: req)
            return req.success(Settings.current)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }

}
