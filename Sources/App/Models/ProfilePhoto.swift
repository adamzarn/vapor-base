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
    
    init(_ req: Request,
         _ userId: UUID,
         ext: String = "",
         existingUrl: String? = nil) {
        self.req = req
        self.userId = userId
        self.ext = ext
        self.existingUrl = existingUrl
    }
    
    // MARK: New and Existing
    
    var folder: String {
        return "\(req.application.environment.name)/images/profile-photos"
    }
    
    var directoryPath: String {
        return "\(req.application.directory.publicDirectory)\(folder)"
    }
    
    var url: String? {
        guard let baseUrl = req.baseUrl else { return nil }
        return "\(baseUrl)/\(folder)/\(filename)"
    }
    
    // MARK: New
    
    var filename: String {
        return "\(userId.uuidString).\(ext)"
    }
    
    var filePath: String {
        return "\(directoryPath)/\(filename)"
    }
    
    // MARK: Existing
    
    var existingFilename: String? {
        guard let url = existingUrl, let filename = url.split(separator: "/").last else { return nil }
        return String(filename)
    }
    
    var existingFilePath: String? {
        guard let filename = existingFilename else { return nil }
        return "\(directoryPath)/\(filename)"
    }
}
