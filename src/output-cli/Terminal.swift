//
//  Terminal.swift
//
//
//  Created by Aaron Jones on 4/28/23.
//

import Foundation

enum TerminalType: String {
    case dumb = "dumb"
    case xterm = "xterm"
    case file = "file"
    case other = "other"
}

struct Terminal {
    var name: String
    var type: TerminalType
    
    var colors: Int {
        switch self.name {
        case "xterm":
            return 8
        case "xterm-16color":
            return 16
        case "xterm-256color":
            return 256
        default:
            return 0
        }
    }
    
    var columns: Int {
        if let colStr = ProcessInfo.processInfo.environment["COLUMNS"] {
            if let colInt: Int = Int(colStr) {
                return colInt
            }
        }
        
        return 80
    }
    
    init() {
        if let term = ProcessInfo.processInfo.environment["TERM"]?.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) {
            self.name = term.isEmpty ? "dumb" : term
            if term.isEmpty || ["dumb", "cons25", "emacs"].contains(term) {
                self.type = .dumb
            } else if term.contains("xterm") {
                self.type = .xterm
            } else {
                self.type = .other
            }
        } else {
            self.name = "dumb"
            self.type = .dumb
        }
    }
}
