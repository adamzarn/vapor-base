//
//  EmailContext.swift
//  App
//
//  Created by Adam Zarn on 10/20/20.
//

import Foundation
import Mailgun
import Vapor

struct EmailContext: Codable {
    let user: User?
    var name: String? {
        return user?.firstName
    }
    let url: String
    let leafTemplate: LeafTemplate
    
    var subject: String {
        switch leafTemplate {
        case .passwordResetEmail: return "Password Reset"
        case .verifyEmailEmail: return "Please verify your email"
        }
    }
    
    func message(from view: View, to user: User) -> MailgunMessage {
        return MailgunMessage(from: MailSettings.from,
                              to: user.email,
                              subject: subject,
                              text: "",
                              html: String(buffer: view.data))
    }
}
