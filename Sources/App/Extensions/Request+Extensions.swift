//
//  Request+Extensions.swift
//  App
//
//  Created by Adam Zarn on 6/20/20.
//

import Foundation
import Vapor

extension Request {
    
    func fail<T>(_ error: Error) -> EventLoopFuture<T> {
        return eventLoop.makeFailedFuture(error)
    }
    
    func success<T>(_ value: T) -> EventLoopFuture<T> {
        return eventLoop.makeSucceededFuture(value)
    }
    
    var baseUrl: String {
        let configuration = application.http.server.configuration
        let scheme = configuration.tlsConfiguration == nil ? "http" : "https"
        let host = configuration.hostname
        let port = configuration.port
        return "\(scheme)://\(host):\(port)"
    }
    
    var searchRange: (Int, Int) {
        guard let start = self.query[Int.self, at: "start"] else {
            return (0, Settings().searchResultLimit)
        }
        guard let end = self.query[Int.self, at: "end"], end >= start else {
            return (start, start + Settings().searchResultLimit)
        }
        return (start, end)
    }
}
