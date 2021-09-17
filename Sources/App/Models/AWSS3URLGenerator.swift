//
//  AWSS3URLGenerator.swift
//  
//
//  Created by Adam Zarn on 9/17/21.
//

import Foundation
import Vapor

struct AWSS3URLGenerator {
    let `protocol`: String = "https"
    let bucket: String
    let service: String = "s3"
    let region: String
    let host: String = "amazonaws.com"
    let key: String

    var url: String {
        return "\(`protocol`)://\(bucket).\(service).\(region).\(host)/\(key)"
    }
    
    init(bucket: String = Environment.s3Bucket,
         region: String = "us-east-2",
         key: String) {
        self.bucket = bucket
        self.region = region
        self.key = key
    }
}
