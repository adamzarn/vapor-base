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
    
    // MARK: Get Settings
    
    func getSettings(req: Request) throws -> EventLoopFuture<CurrentSettings> {
        do {
            _ = try AuthUtility.getAuthorizedUser(req: req)
            return req.success(Settings.current)
        } catch let error {
            return AuthUtility.getFailedFuture(for: error, req: req)
        }
    }

}
