//
//  ViewController.swift
//  App
//
//  Created by Adam Zarn on 10/13/20.
//

import Foundation
import Vapor
import Leaf

struct Context: Codable {
    let baseUrl: String
}

class ViewController: RouteCollection {
    
    func boot(routes: RoutesBuilder) throws {
        
        let viewRoute = routes.grouped("view")
        viewRoute.get("signUp", use: signUp)
        viewRoute.get("login", use: login)
        
    }
    
    func signUp(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("sign-up", Context(baseUrl: req.baseUrl))
    }
    
    func login(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("login", Context(baseUrl: req.baseUrl))
    }

}
