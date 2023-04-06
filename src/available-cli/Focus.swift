//
//  Focus.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import OSAKit
import SystemConfiguration

/// Allows for creation of date objects using milliseconds since 1970 (Unix Epoch)
/// - Author: Travis Griggs (https://stackoverflow.com/questions/40134323/date-to-milliseconds-and-back-to-date-in-swift)
extension Date {
    var millisecondsSince1970:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Float) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

/// Codable Model for ~/Library/DoNotDisturb/DB/Assertions.json
/// - Authors: Original Credit to Yusuf Özgül (https://github.com/yusufozgul/SyncFocusWithSlack/)
///           Modified for additional fields by Aaron Jones <am@jonesiscoding.com>
struct AssertionModel: Codable {
    let data: [Assertion]
 
    struct Assertion: Codable {
        let storeAssertionRecords: [StoreAssertionRecord]
    }

    struct StoreAssertionRecord: Codable {
        let assertionDetails: StoreAssertionRecordAssertionDetails
        let assertionStartDateTimestamp: Float
    }

    struct StoreAssertionRecordAssertionDetails: Codable {
        let assertionDetailsModeIdentifier: String
        let assertionDetailsReason: String?
    }
}

/// Codable Model for ~/Library/DoNotDisturb/DB/ModeConfiguration.json
/// - Authors: Original Credit to Yusuf Özgül (https://github.com/yusufozgul/SyncFocusWithSlack/)
///           Modified for additional and optional fields by Aaron Jones <am@jonesiscoding.com>
struct ModeConfig: Codable {
    let data: [Config]

    struct Config: Codable {
        let modeConfigurations: [String : COMApple]
    }

    struct COMApple: Codable {
        let triggers: TriggerConfig
        let mode: Mode
    }
    
    struct TriggerConfig: Codable {
        let triggers: [Trigger]
    }
    
    struct Trigger: Codable {
        let timePeriodEndTimeHour: Int
        let timePeriodStartTimeHour: Int
        let timePeriodStartTimeMinute: Int
        let timePeriodWeekdays: Int
        let timePeriodEndTimeMinute: Int
        let enabledSetting: Int
        
        enum CodingKeys: String, CodingKey {
            case timePeriodEndTimeHour = "timePeriodEndTimeHour"
            case timePeriodStartTimeHour = "timePeriodStartTimeHour"
            case timePeriodStartTimeMinute = "timePeriodStartTimeMinute"
            case timePeriodEndTimeMinute = "timePeriodEndTimeMinute"
            case enabledSetting = "enabledSetting"
            case timePeriodWeekdays = "timePeriodWeekdays"
        }
        
        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            self.timePeriodEndTimeHour = try values.decodeIfPresent(Int.self, forKey: .timePeriodEndTimeHour) ?? 0
            self.timePeriodStartTimeHour = try values.decodeIfPresent(Int.self, forKey: .timePeriodStartTimeHour) ?? 0
            self.timePeriodStartTimeMinute = try values.decodeIfPresent(Int.self, forKey: .timePeriodStartTimeMinute) ?? 0
            self.timePeriodEndTimeMinute = try values.decodeIfPresent(Int.self, forKey: .timePeriodEndTimeMinute) ?? 0
            self.timePeriodWeekdays = try values.decodeIfPresent(Int.self, forKey: .timePeriodWeekdays) ?? 0
            self.enabledSetting = try values.decode(Int.self, forKey: .enabledSetting)
        }
    }

    struct Mode: Codable {
        let name: String
    }
}

/// Object representing a focus mode in macOS.  In Catalina & Big Sur, retrieves Do Not Disturb status.  On Monterey and up, retreives Focus status & name.
/// 
/// - Parameter user: The username for which to retrieve focus information.  If not given, will default to the current console user.
///
struct Focus {
    var user: String?
    
    init(user: String? = nil) {
        self.user = user
    }
    
    func isActive() throws -> Bool {
        let mode = try self.getMode()

        return mode.isEmpty ? false : true
    }
    
    func getMode() throws -> String {
        if #available(macOS 12.0, *) {
            let focusMonty = try FocusMonterey(username: self.user)
            
            return focusMonty.getMode()
        }
        
        if #available(macOS 11.0, *) {
                let focusBiggy = try FocusBigSur(username: self.user)
                
                return try focusBiggy.isDoNotDisturb() ? "Do Not Disturb" : ""
        }
                
        if #available(macOS 10.15, *) {
            let focusCaty = try FocusCatalina(username: self.user)
            
            return try focusCaty.isDoNotDisturb() ? "Do Not Disturb" : ""
        }
        
        return ""
    }
}

enum FocusError: Error {
    case invalidUser(user: String)
    case decoderError(error: String)
}

/// Base class for version specific focus classes to extend.  Ensures that we have a user directory.
/// - Parameter user: The username to utilize.  If not given, defaults to the console user.
class FocusBase {
    var user: MacUser?
    
    init(username: String? = nil) throws {
        if let resolved: String = username {
            let localUser: LocalUser = try LocalUser(username: resolved)
            self.user = localUser
        } else {
            if let consoleUser: MacUser = try LocalUser.fromConsole() {
                self.user = consoleUser
            }
        }
    }
    
    func plistFromData(_ data: Data) throws -> [String:Any] {
        try PropertyListSerialization.propertyList(
            from: data,
            format: nil
        ) as! [String:Any]
    }
}

/// Reads the doNotDisturb status from macOS Catalina
/// - Parameter user: The username to utilize.  If not given, defaults to the console user.
class FocusCatalina: FocusBase {
    /// Evaluates the doNotDisturb Status
    ///
    /// - Returns: Bool
    /// - Throws: If preferences cannot be decoded
    func isDoNotDisturb() throws -> Bool {
        if let user = self.user {
            let ncprefsUrl = URL(
                fileURLWithPath: String("\(user.userHome.path)/Library/Preferences/ByHost/com.apple.notificationcenterui")
            )
            
            let fm = FileManager()
            if fm.fileExists(atPath: ncprefsUrl.path) {
                do {
                    let prefsList = try plistFromData(try Data(contentsOf: ncprefsUrl))
                    if let dndPrefsData = prefsList["doNotDisturb"] as? String {
                        if(!dndPrefsData.isEmpty && dndPrefsData != "0") {
                            return true
                        }
                    }
                } catch {
                    throw FocusError.decoderError(error: "Could not decode com.apple.notificationcenterui")
                }
            }
        }
        
        return false
    }
}

/// Reads the DoNotDisturb status in macOS Big Sur.
///
/// - Authors:  Originally written by Bart Reardon (https://github.com/bartreardon/infocus/blob/main/infocus/checkDNDcli.swift)
///            Modified for error handling by Aaron Jones <am@jonesiscoding>
/// - Parameter user: The username to utilize.  If not given, defaults to the console user.
class FocusBigSur: FocusBase {
    /// Evaluates the DoNotDisturb status
    /// - Returns:  Bool
    /// - Throws:   If preferences cannot decoded.
    func isDoNotDisturb() throws -> Bool {
        if let user = self.user {
            let ncprefsUrl = URL(
                fileURLWithPath: String("\(user.userHome.path)/Library/Preferences/com.apple.ncprefs.plist")
            )
            
            let fm = FileManager()
            if fm.fileExists(atPath: ncprefsUrl.path) {
                do {
                    let prefsList = try plistFromData(try Data(contentsOf: ncprefsUrl))
                    let dndPrefsData = prefsList["dnd_prefs"] as! Data
                    let dndPrefsList = try plistFromData(dndPrefsData)
                    
                    if let userPref = dndPrefsList["userPref"] as? [String:Any] {
                        return userPref["enabled"] as! Bool
                    }
                } catch {
                    throw FocusError.decoderError(error: "Could not decode com.apple.ncprefs.")
                }
            }
        }
        
        return false
    }
}

/// Functions to read the Focus Mode from macOS Monterey and Ventura
///
/// - Parameter user: The username to utilize.  If not given, defaults to the console user.
class FocusMonterey: FocusBase {

    /// Reads Focus mode from User's Library/DoNotDisturb/DB/Assertions.json, being careful with order of precedence (least to greatest import):  Smart Trigger, Scheduled Trigger, Manually Set.
    /// If the file is not available or cannot be properly parsed, returns no focus mode.
    ///
    /// - Authors:  Originally written by Drew Kerr (https://gist.github.com/drewkerr/0f2b61ce34e2b9e3ce0ec6a92ab05c18)
    ///            Modified for order of precedence & ported to Swift by Aaron Jones <am@jonesiscoding.com>
    ///
    /// - Returns:  The current focus mode in the form of a string.  A blank string indicates no focus mode.
    func getMode() -> String {
        var focus: String = ""
        if let user = self.user {
            let fm = FileManager()
            let assertFile = URL(fileURLWithPath: "\(user.userHome.path)/Library/DoNotDisturb/DB/Assertions.json")
            let modeConfigFile = URL(fileURLWithPath: "\(user.userHome.path)/Library/DoNotDisturb/DB/ModeConfigurations.json")
            let jsonDecoder = JSONDecoder()
            var manualStart: Int = 0
            
            if fm.fileExists(atPath: assertFile.path) && fm.fileExists(atPath: modeConfigFile.path) {
                let calendar = Calendar.current
                let modeConfiguration = try? jsonDecoder.decode(ModeConfig.self, from: Data(contentsOf: modeConfigFile))
                if let focusModesDictionary = modeConfiguration?.data.first?.modeConfigurations {
                    if let assertions = try? jsonDecoder.decode(AssertionModel.self, from: Data(contentsOf: assertFile)) {
                        if let record = assertions.data.first?.storeAssertionRecords.first {
                            let details = record.assertionDetails
                            let activeFocusId = details.assertionDetailsModeIdentifier
                            focus = focusModesDictionary[activeFocusId]?.mode.name ?? focus
                            if(details.assertionDetailsReason != "user-action") {
                                // seems like a smart trigger, let's get the time for comparison.
                                let ms = (record.assertionStartDateTimestamp + 978307200) * 1000
                                let dt = calendar.dateComponents([.hour, .minute], from: Date(milliseconds: ms))
                                manualStart = (dt.hour ?? 0) * 60 + (dt.minute ?? 0)
                            } else {
                                return focus
                            }
                        }
                    }

                    let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())
                    let now = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)

                    for (_, config) in focusModesDictionary {
                        if let triggers = config.triggers.triggers.first {
                            if(triggers.enabledSetting == 2) {
                                let start = triggers.timePeriodStartTimeHour * 60 + triggers.timePeriodStartTimeMinute
                                let end = triggers.timePeriodEndTimeHour * 60 + triggers.timePeriodEndTimeMinute
                                if (start < end) {
                                    if (now >= start && now < end) {
                                        if(manualStart > 0 && manualStart < start) {
                                            if(manualStart > start) {
                                                focus = config.mode.name
                                            }
                                         } else {
                                             focus = config.mode.name
                                         }
                                    }
                                } else if (start > end) {
                                    if (now >= start || now < end) {
                                        if(manualStart > 0) {
                                            if(manualStart >= start || manualStart < end) {
                                                focus = config.mode.name
                                            }
                                        } else {
                                            focus = config.mode.name
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    return focus
                }
            }
        }
        
        return focus
    }
}
