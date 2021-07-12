//
//  MailgunDomain+Extension.swift
//  App
//
//  Created by Adam Zarn on 10/3/20.
//

import Foundation
import Mailgun
import Vapor

extension MailgunDomain {
    static var sandboxDomain: MailgunDomain { .init(Environment.mailgunSandboxDomain, .us) }
    static var defaultDomain: MailgunDomain { .init(Environment.mailgunDefaultDomain, .us) }
}
