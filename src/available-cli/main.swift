//
//  main.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import Commands


var isCamera:Bool = false
var isZoom:Bool = false
var isGoToMeeting:Bool = false
var isTeams:Bool = false
var isWebEx:Bool = false
var isPresenting:Bool = false
var isFocus:Bool = false
var isEncrypting:Bool = false
var isBatteryPower:Bool = false
var isQuiet:Bool = false
var isAvailable:Bool = true
var isExcludeWork:Bool = false
var isMetered:Bool = false
var isVersion:Bool = false
var isVerbose:Bool = false

func notAvailable(label: String, value: String) -> Bool {
    if(!isQuiet) {
        print("\(label.style(ANSIAttr.cyan)) : \(value)")
    }
    
    return isQuiet
}

var aUser: String? = nil
if(CommandLine.arguments.count > 1) {
    for arg in CommandLine.arguments {
        if arg.hasPrefix("--") {
            if(arg == "--all") {
                isCamera = true
                isZoom = true
                isGoToMeeting = true
                isTeams = true
                isWebEx = true
                isPresenting = true
                isFocus = true
                isBatteryPower = true
                isMetered = true
                isEncrypting = true
            } else if (arg == "--recommended") {
                isCamera = true
                isPresenting = true
                isFocus = true
                isExcludeWork = true
                isEncrypting = true
            } else {
                isCamera = (arg == "--camera") ? true : isCamera
                isZoom = (arg == "--zoom") ? true : isZoom
                isGoToMeeting = (arg == "--gotomeeting") ? true : isGoToMeeting
                isTeams = (arg == "--teams") ? true : isTeams
                isWebEx = (arg == "--webex") ? true : isWebEx
                isPresenting = (arg == "--presenting") ? true : isPresenting
                isFocus = (arg == "--focus") ? true : isFocus
                isBatteryPower = (arg == "--power") ? true : isBatteryPower
                isEncrypting = (arg == "--filevault") ? true : isEncrypting
                isMetered = (arg == "--metered") ? true : isMetered
                isQuiet = (arg == "--quiet") ? true : isQuiet
                isVerbose = (arg == "--verbose") ? true : isVerbose
                isExcludeWork = (arg == "--nowork") ? true : isExcludeWork
                isVersion = (arg == "--version") ? true: isVersion
            }
        } else if(CommandLine.arguments[0] != arg) {
            aUser = arg
        }
    }
    
    if(isVersion) {
        let cli:String = CommandLine.arguments[0]
        let myUrl:URL = URL(fileURLWithPath: cli)
        let resources = myUrl.deletingLastPathComponent()
        let contents = resources.deletingLastPathComponent()
        let plist = URL(fileURLWithPath: "\(contents.path)/Info.plist")
        let result = Commands.Bash.run("defaults read \"\(plist.path)\" CFBundleShortVersionString")
        if result.isSuccess {
            print("Available CLI v\(result.output)")
            exit(0)
        } else {
            print(result.errorOutput)
            print("Available CLI (removed from application bundle)")
            exit(1)
        }
    }
    
    // Camera
    if(isCamera) {
        let cameraStatus = try CameraStatus(from: cameras)
        
        if(cameraStatus.output() && !isVerbose) {
            exit(cameraStatus.status ? 1 : 0)
        }
    }
    
    // Zoom
    if(isZoom) {
        let zoom = Zoom()
        let zoomStatus = ZoomStatus(from: zoom)
        
        if(zoomStatus.output() && !isVerbose) {
            exit(zoomStatus.status ? 1 : 0)
        }
    }
    
    // GotoMeeting
    if(isGoToMeeting) {
        let gtm = GoToMeeting()
        let gtmStatus = GoToMeetingStatus(from: gtm)
        
        if(gtmStatus.output() && !isVerbose) {
            exit(gtmStatus.status ? 1 : 0)
        }
    }

    // WebEx
    if(isWebEx) {
        let wx = WebEx()
        let wxStatus = WebExStatus(from: wx)
        
        if(wxStatus.output() && !isVerbose) {
            exit(wxStatus.status ? 1 : 0)
        }
    }

    // Teams
    if(isTeams) {
        let teams = try Teams(user: aUser)
        let teamsStatus = TeamsStatus(from: teams)
        
        if(teamsStatus.output() && !isVerbose) {
            exit(teamsStatus.status ? 1 : 0)
        }
    }
    
    // Presenting
    if(isPresenting) {
        let display = NoDisplaySleep()
        let displayStatus = PresentingStatus(from: display)
    
        if(displayStatus.output() && !isVerbose) {
            exit(displayStatus.status ? 1 : 0)
        }
    }
    
    // Focus
    if(isFocus) {
        let focus = Focus(user: aUser)
        let focusStatus = try FocusModeStatus(from: focus, ignore: isExcludeWork ? ["Work"] : [])
        
        if(focusStatus.output() && !isVerbose) {
            exit(focusStatus.status ? 1 : 0)
        }
    }
    
    let system = System()
    if(isEncrypting) {
        let encryptStatus = FileVaultStatus(from: system)
        
        if(encryptStatus.output() && !isVerbose) {
            exit(encryptStatus.status ? 1 : 0)
        }
    }

    if(isBatteryPower) {
        let powerStatus = BatteryPowerStatus(from: system)
        
        if(powerStatus.output() && !isVerbose) {
            exit(powerStatus.status ? 1 : 0)
        }
    }

    if(isMetered) {
        let network = MeteredNetwork()
        let meteredStatus = MeteredNetworkStatus(from: network)
        
        if(meteredStatus.output() && !isVerbose) {
            exit(meteredStatus.status ? 1 : 0)
        }
    }
    
    exit(0)
}
