//
//  Stub.swift
//  available-cli
//
//  Created by Aaron Jones on 4/27/23.
//

import Foundation
import ArgumentParser

let _user: MacUser? = try? LocalUser.fromConsole()

enum StatusFlags: String, CaseIterable, EnumerableFlag {
    case camera = "camera"
    case zoom = "zoom"
    case gotomeeting = "gotomeeting"
    case teams = "teams"
    case webex = "webex"
    case presenting = "presenting"
    case focus = "focus"
    case filevault = "filevault"
    case power = "power"
    case metered = "metered"
    case user = "user"
    case system = "system"
    case all = "all"
    
    static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .camera:
            return "Evaluate Camera Status"
        case .zoom:
            return "Evaluate Zoom Meeting Status"
        case .gotomeeting:
            return "Evaluate GotoMeeting Status"
        case .teams:
            return "Evaluate Microsoft Teams Call Status"
        case .webex:
            return "Evaluates WebEx Call Status"
        case .presenting:
            return "Evaluate 'No Sleep' Display Assertions"
        case .focus:
            return "Evaluate Focus Mode"
        case .user:
            return "Evaluate Only User Specific Conditions, listed above."
        case .power:
            return "Evaluate AC Power Status"
        case .filevault:
            return "Evaluate FileVault Encryption Progress"
        case .metered:
            return "Evaluate 'Low Data Mode' Connection"
        case .system:
            return "Evaluate Only System Specific Conditions <filevault, metered, system>"
        case .all:
            return "Evaluate All Conditions"
        }
    }
    
    static var userCases: [StatusFlags] {
        return StatusFlags.allCases.filter { !StatusFlags.systemCases.contains($0) && !StatusFlags.convenienceCases.contains($0) }
    }
    
    static var systemCases: [StatusFlags] {
        return [.metered,.filevault,.power]
    }
    
    static var convenienceCases: [StatusFlags] {
        return [.all,.user,.system]
    }
    
    static var superuserCases: [StatusFlags] {
        return [.user,.focus,.teams,.all]
    }
    
    func status(user: MacUser?) throws -> UserStatus? {
        switch self {
        case .camera:
            return try CameraStatus(from: cameras)
        case .zoom:
            return ZoomStatus(from: Zoom())
        case .gotomeeting:
            return GoToMeetingStatus(from: GoToMeeting())
        case .teams:
            return TeamsStatus(from: try Teams(user: user))
        case .webex:
            return WebExStatus(from: WebEx())
        case .presenting:
            return PresentingStatus(from: NoDisplaySleep())
        case .focus:
            return try FocusModeStatus(from: Focus(user: user), ignore: [])
        case .filevault:
            return FileVaultStatus(from: System())
        case .power:
            return BatteryPowerStatus(from: System())
        case .metered:
            return MeteredNetworkStatus(from: MeteredNetwork())
        default:
            return nil
        }
    }
}

@main
struct AvailableCli: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "available-cli",
        abstract: "Evaluates whether the current console user is available for interaction based on the given flags.",
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    )
    
    @Flag()
    var conditions: [StatusFlags] = [StatusFlags.user]
    
    @Flag(help: "Exclude the 'Work' focus mode when evaluating Focus Mode")
    var noWork: Bool = false
    
    @Flag(name: .shortAndLong, help: "No output. Exits with error status if user is unavailable")
    var quiet: Bool = false
    
    @Flag(name: .shortAndLong, help: "Display details of all conditions")
    var verbose: Int

    func normalize() -> [StatusFlags] {
        if(self.conditions.contains(.all)) { return StatusFlags.allCases }
        if(self.conditions.contains(.user)) { return StatusFlags.userCases }
        if(self.conditions.contains(.system)) { return StatusFlags.systemCases }
        
        return self.conditions
    }
    
    mutating func validate() throws {
        if let user: MacUser = _user {
            let whoami: String = NSUserName()
            if(whoami != user.username) {
                if !FileManager.default.isReadableFile(atPath: "\(user.userHome.path)/Desktop") {
                    for flag in self.conditions {
                        if StatusFlags.superuserCases.contains(flag) {
                            throw ValidationError("You must run this tool as a superuser to use the --\(flag.rawValue) flag.")
                        }
                    }
                }
            }
        }
    }

    mutating func run() throws {
        if let user: MacUser = _user {
            let normalized: [StatusFlags] = self.normalize()
            var allAvailable: Bool = true
            if(self.verbose != 0) {
                print("")
            }
            for condition in normalized {
                if let status: UserStatus = try condition.status(user: user) {
                    let isException: Bool = (status.slug == "focus-Work" && self.noWork)
                    allAvailable = allAvailable ? (status.status && !isException) : false
                    if self.verbose != 0 {
                        print(status.label.style(ANSIAttr.cyan).padding(toLength: 76, withPad: ".", startingAt: 0), terminator: " ")
                        let style: ANSIAttr = (status.status && !isException) ? .green : .red
                        print("[\(status.value.style(style))]")
                    } else {
                        if(status.status && !isException ) {
                            if self.quiet {
                                throw ExitCode(1)
                            } else {
                                print(status.slug)
                                throw ExitCode(1)
                            }
                        }
                    }
                }
            }
            
            print("")
            if(allAvailable) {
                AvailableCli.exit()
            } else {
                throw ExitCode(1)
            }
        } else {
            if self.verbose != 0 {
                throw RuntimeError("No User Logged In".style(.red))
            } else if self.quiet {
                throw ExitCode(1)
            } else {
                throw RuntimeError("none")
            }
        }
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}
