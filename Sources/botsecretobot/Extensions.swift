//
//  Extensions.swift
//  botsecretobot
//
//  Created by Wellington Nascente Hirsch on 01/09/21.
//

import Foundation
import TelegramBotSDK

// MARK: - User from TelegramBotSDK
extension User {
    
    var firstNameOrUsername: String {
        if let username = self.username {
            return "@\(username)"
        } else {
            return firstName
        }
    }
}

// MARK: - String
extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localizedWithArgs(_ arguments: CVarArg...) -> String {
        return String(format: localized, arguments)
    }
}
