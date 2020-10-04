//
//  Request+Extensions.swift
//  App
//
//  Created by Adam Zarn on 6/20/20.
//

import Foundation
import Vapor

extension Request {
    
    func fail<T>(_ error: AbortError) -> EventLoopFuture<T> {
        return self.eventLoop.makeFailedFuture(error)
    }
    
}
