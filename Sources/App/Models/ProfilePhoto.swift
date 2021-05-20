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
    
    let folder = "images/profile-photos"
    
    var directoryPath: String {
        return "\(req.application.directory.publicDirectory)/\(folder)"
    }
    
    var filename: String {
        return "\(userId.uuidString).\(ext)"
    }
    
    var filePath: String {
        return "\(directoryPath)/\(filename)"
    }
    
    var url: String {
        return "\(req.baseUrl)/\(folder)/\(filename)"
    }
}
