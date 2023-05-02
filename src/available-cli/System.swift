//
//  System.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import Commands

/// Contains methods for evaluating if system is encrypting FileVault, on AC power.
struct System {
    var isEncrypting: Bool {
        let fm = FileManager()
        if fm.fileExists(atPath: "/usr/bin/fdesetup") {
            let result = Commands.Bash.run("/usr/bin/fdesetup status | /usr/bin/grep -q 'Encryption in progress'")
            if result.isSuccess {
              return true
            }
        }

        return false
    }
    
    var isAcPower: Bool {
        let result = Commands.Bash.run("/usr/bin/pmset -g ps | /usr/bin/grep -q \"AC Power\"")
        if result.isSuccess {
            return true
        }

        return false
    }
}

/// Determines if a network connection on this macOS system is marked as 'low data'
///
/// - Authors: Aaron M Jones <am@jonesiscoding.com> (Swift Implementation)
///           Alex Zenla <https://github.com/azenla/MacHack> (Original Information)
///
struct MeteredNetwork {
    var isExpensive: Bool
    var isConstrained: Bool
    var isMetered: Bool {
        return self.isExpensive || self.isConstrained
    }

    init() {
        let testSite = "http://httpstat.us/200"
        let result = Commands.Bash.run("/usr/bin/nscurl --max-time 1 --insecure --no-constrained --no-expensive -o /dev/null \"\(testSite)\"")
        
        if(result.output.contains("constrained") || result.errorOutput.contains("constrained")) {
            self.isConstrained = true
        } else {
            self.isConstrained = false
        }
        
        if(result.output.contains("expensive") || result.errorOutput.contains("expensive")) {
            self.isExpensive = true
        } else {
            self.isExpensive = false
        }
    }
}
