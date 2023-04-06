//
//  Online.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import Commands
import SystemConfiguration

/// Retrieves the active status of GoToMeeting
///
/// - Authors: brunerd (https://www.brunerd.com/blog/2022/03/07/respecting-focus-and-meeting-status-in-your-mac-scripts-aka-dont-be-a-jerk/)
struct GoToMeeting {
    var active: Bool {
        let result = Commands.Bash.run("/usr/bin/pgrep \"GoTo Helper \\(Plugin\\)\" &>/dev/null && return 0")
        if result.isSuccess {
          return true
        }

        return false
    }
}

/// Retrieves the active status of WebEx
///
/// - Authors: brunerd (https://www.brunerd.com/blog/2022/03/07/respecting-focus-and-meeting-status-in-your-mac-scripts-aka-dont-be-a-jerk/)
struct WebEx {
    var active: Bool {
        let result = Commands.Bash.run("/bin/ps auxww | /usr/bin/grep -q \"[(]WebexAppLauncher)\"")
        if result.isSuccess {
          return true
        }

        return false
    }
}

/// Retrieves the active status of Zoom
///
/// - Authors: brunerd (https://www.brunerd.com/blog/2022/03/07/respecting-focus-and-meeting-status-in-your-mac-scripts-aka-dont-be-a-jerk/)
struct Zoom {
    var active: Bool {
        let result = Commands.Bash.run("/usr/bin/pgrep \"CptHost\" &>/dev/null")
        if result.isSuccess {
          return true
        }

        return false
    }
}

struct TeamsAppStates: Codable {
    var states: String
    var lastStateTime: Float
    
    func isActive() -> Bool {
        let stateList: [String] = self.states.split(separator: ",").map(String.init)
        var callStarted: Bool = false
        var callEnded: Bool = false
        for state in stateList {
            switch(state) {
            case "InCall":
                callStarted = true
            case "CallEnded":
                callEnded = true
            case "Unloaded":
                callEnded = true
            case "Interactive":
                callEnded = true
            default:
                break
            }
        }
            
        if(callStarted && !callEnded) {
            return true
        }
            
        return false
    }
}

struct TeamsStorage: Codable {
    var appStates: TeamsAppStates
    var webAppStates: TeamsAppStates
}

/// Retrieves the active status of Microsoft Teams
///
/// - Authors: brunerd <https://www.brunerd.com/blog/2022/03/07/respecting-focus-and-meeting-status-in-your-mac-scripts-aka-dont-be-a-jerk/> (Original)
///           Aaron M Jones <am@jonesiscoding.com> (Modified to allow for better detection of end of calls, adapted to Swift)
struct Teams {
    var user: MacUser?
    
    init(user: String? = nil) throws {
        if let resolved: String = user {
            let localUser: LocalUser = try LocalUser(username: resolved)
            self.user = localUser
        } else {
            if let consoleUser: MacUser = try LocalUser.fromConsole() {
                self.user = consoleUser
            }
        }
    }
    
    var active: Bool {
        if let user = self.user {
            let teamsJson="\(user.userHome.path)/Library/Application Support/Microsoft/Teams/storage.json"
            let fm = FileManager()
            if fm.fileExists(atPath: teamsJson) {
                let teamsUrl = URL(fileURLWithPath: teamsJson)
                guard let data = try? Data(contentsOf: teamsUrl) else {
                    return false
                }

                let decoder = JSONDecoder()
                do {
                    let teamsStorage = try decoder.decode(TeamsStorage.self, from: data)
                    
                    if(teamsStorage.appStates.isActive() || teamsStorage.webAppStates.isActive()) {
                        return true
                    }
                } catch {
                    return false
                }
            }
        }
        
        return false
    }
}
