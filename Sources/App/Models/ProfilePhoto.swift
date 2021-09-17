//
//  ProfilePhoto.swift
//  App
//
//  Created by Adam Zarn on 5/20/21.
//

import Foundation
import Vapor

struct ProfilePhoto: Content {
    var file: File
}

struct ProfilePhotoInfo {
    let req: Request
    let userId: UUID
    let ext: String
    let existingUrl: String?
    let timestamp: String
    
    init(_ req: Request,
         _ userId: UUID,
         ext: String = "",
         existingUrl: String? = nil) {
        self.req = req
        self.userId = userId
        self.ext = ext
        self.existingUrl = existingUrl
        self.timestamp = PhotoTimestamp.current
    }
    
    var filename: String {
        return "\(userId.uuidString)-\(timestamp).\(ext)"
    }
    
    var awsUrl: String {
        return AWSS3URLGenerator(key: filename).url
    }

    var existingFilename: String? {
        guard let url = existingUrl, let filename = url.split(separator: "/").last else { return nil }
        return String(filename)
    }
}
