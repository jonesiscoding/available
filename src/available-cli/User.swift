//
//  User.swift
//

import Foundation
import SystemConfiguration

enum UserError: Error {
    case invalidUser(user: String)
    case invalidHome(user: String)
}

class UserValidator {
    static let invalid: [String] = ["loginwindow"]
    
    static func isValid(username: String) -> Bool {
        if(!username.isEmpty && !UserValidator.invalid.contains(username)) {
            return true
        }
        
        return false
    }
}

protocol MacUser {
    var username: String { get }
    var userHome: URL { get }
}

extension MacUser {
    static func fromConsole() throws -> MacUser? {
        if let consoleUser: CFString = SCDynamicStoreCopyConsoleUser(nil, nil, nil) {
            if let username: String = consoleUser as String? {
                if(UserValidator.isValid(username: username)) {
                    return try LocalUser(username)
                }
            }
        }
        
        return nil
    }
}

class LocalUser: MacUser {
    var username: String
    var userHome: URL
    
    init(_ username: String) throws {
        if(!UserValidator.isValid(username: username)) {
            throw UserError.invalidUser(user: username)
        }
        
        self.username = username
        if let home = FileManager.default.homeDirectory(forUser: username) {
            self.userHome = home
        } else {
            throw UserError.invalidHome(user: username)
        }
    }
}

