//
//  Online.swift
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

/// Retrieves the active status of Teams "Work or School" or Teams Classic.
struct Teams {
    var user: MacUser?

    init(user: MacUser? = nil) throws {
        if let resolved: MacUser = user {
            self.user = resolved
        } else {
            if let consoleUser: MacUser = try LocalUser.fromConsole() {
                self.user = consoleUser
            }
        }
    }

    var active: Bool {
        let teamsWork = TeamsWork()
        if teamsWork.active {
            return true
        }

        if let user = self.user {
            do {
                let teamsClassic = try TeamsClassic(user: user)
                if teamsClassic.active {
                    return true
                }
            } catch {
                return false
            }
        }

        return false
    }
}

/// Retrieves the active status of Teams "Work or School"
struct TeamsWork {
    var active: Bool {
        // There might be a Swift way to do this,
        let result = Commands.Bash.run("pmset -g | grep \"display sleep prevented by\" | grep \"MSTeams\"")
        if result.isSuccess {
          return true
        }

        return false
    }
}

struct TeamsClassicAppStates: Codable {
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

struct TeamsClassicStorage: Codable {
    var appStates: TeamsClassicAppStates
    var webAppStates: TeamsClassicAppStates
}

/// Retrieves the active status of Microsoft Teams Classic
///
/// - Authors: brunerd <https://www.brunerd.com/blog/2022/03/07/respecting-focus-and-meeting-status-in-your-mac-scripts-aka-dont-be-a-jerk/> (Original)
///            Aaron M Jones <am@jonesiscoding.com> (Modified to allow for better detection of end of calls, adapted to Swift)
struct TeamsClassic {
    var user: MacUser?
    
    init(user: MacUser? = nil) throws {
        if let resolved: MacUser = user {
            self.user = resolved
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
                if isFileCurrent(url: teamsUrl) {
                    guard let data = try? Data(contentsOf: teamsUrl) else {
                        return false
                    }

                    let decoder = JSONDecoder()
                    do {
                        let teamsStorage = try decoder.decode(TeamsClassicStorage.self, from: data)
                        
                        if(teamsStorage.appStates.isActive() || teamsStorage.webAppStates.isActive()) {
                            return true
                        }
                    } catch {
                        return false
                    }
                }
            }
        }
        
        return false
    }
    
    func isFileCurrent(url: URL) -> Bool {
        guard let start = fileModificationDate(url: url) else { return false }
        let timeToLive: TimeInterval = 60 * 60 * 24 // 60 seconds * 60 minutes * 24 hours
        
        return Date().timeIntervalSince(start) <= timeToLive
    }
    
    func fileModificationDate(url: URL) -> Date? {
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}
