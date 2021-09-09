//
//  Request+Extensions.swift
//  App
//
//  Created by Adam Zarn on 6/20/20.
//

import Foundation
import Vapor
import SotoS3

extension Request {
    var aws: AWS {
        .init(request: self)
    }

    struct AWS {
        var client: AWSClient {
            return request.application.aws.client
        }

        let request: Request
    }
    
    var s3: S3 {
        return S3(client: aws.client, region: .useast2)
    }
    
    func fail<T>(_ error: Error) -> EventLoopFuture<T> {
        return eventLoop.makeFailedFuture(error)
    }
    
    func success<T>(_ value: T) -> EventLoopFuture<T> {
        return eventLoop.makeSucceededFuture(value)
    }
    
    var scheme: String {
        switch application.environment {
        case .production: return "https"
        default: return "http"
        }
    }
    
    var firstHost: String? {
        if application.environment == .testing {
            return "localhost:8080"
        }
        return headers["Host"].first
    }
    
    var baseUrl: String? {
        guard let host = firstHost else { return nil }
        return "\(scheme)://\(host)"
    }
    
    var searchRange: (Int, Int) {
        guard let start = self.query[Int.self, at: "start"] else {
            return (0, Settings.searchResultLimit)
        }
        guard let end = self.query[Int.self, at: "end"], end >= start else {
            return (start, start + Settings.searchResultLimit)
        }
        return (start, end)
    }
    
    var testing: Bool {
        return application.environment == .testing
    }
    
    func userId(defaultToIdOf loggedInUser: User) -> UUID? {
        var uuidString = parameters.get("userId") ?? loggedInUser.id?.uuidString
        if uuidString == "me" { uuidString = loggedInUser.id?.uuidString }
        guard let userId = uuidString else { return nil }
        return UUID(userId)
    }
    
    func sendEmail(to user: User, tokenId: String, context: EmailContext) -> EventLoopFuture<String> {
        guard !testing else { return success(tokenId) }
        return leaf.render(context.leafTemplate.rawValue, context).flatMapThrowing { view in
            _ = self.mailgun().send(context.message(from: view, to: user)).always { response in
                print(response)
            }
            // The tokenId is sent back in the testing environment,
            // but in production, the tokenId should only be accessible via email.
            return ""
        }
    }
}
