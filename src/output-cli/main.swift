//
//  main.swift
//  output-cli
//
//  Created by Aaron Jones on 3/21/23.
//

import Foundation
import Commands

enum OutputType: String, CaseIterable {
    case notify = "notify"
    case line = "line"
    case badge = "badge"
    case inline = "inline"
    case section = "section"
    case endsection = "endsection"
}

enum OutputVerbosity: String, CaseIterable {
    case quiet = "quiet"
    case verbose = "verbose"
    case normal = "normal"
    case very_verbose = "very-verbose"
}

var msg: String = ""
var type: OutputType = .line
var context: OutputContext = .normal
var verbosity: OutputVerbosity = .normal
var output: Output = Output(level: 1)
var isVersion: Bool = false
if(CommandLine.arguments.count > 1) {
    for arg in CommandLine.arguments {
        
        if arg.hasPrefix("-v") {
            switch(arg) {
            case "-vv":
                verbosity = .very_verbose
            case "-v":
                verbosity = .verbose
            default:
                break
            }
        }
        
        if arg.hasPrefix("--") {
            let flag = arg.dropFirst(2)
            
            if(flag == "version") {
                isVersion = true
            }
            
            for oType in OutputType.allCases {
                if(oType.rawValue == flag) {
                    type = oType
                }
            }
            
            for oContext in OutputContext.allCases {
                if(oContext.rawValue == flag) {
                    context = oContext
                }
            }
            
            for oVerbosity in OutputVerbosity.allCases {
                if(oVerbosity.rawValue == flag) {
                    verbosity = oVerbosity
                }
            }
        } else {
            msg = arg
        }
    }
}

// Output version number only
if(isVersion) {
    let cli:String = CommandLine.arguments[0]
    let myUrl:URL = URL(fileURLWithPath: cli)
    let resources = myUrl.deletingLastPathComponent()
    let contents = resources.deletingLastPathComponent()
    let plist = URL(fileURLWithPath: "\(contents.path)/Info.plist")
    let result = Commands.Bash.run("defaults read \"\(plist.path)\" CFBundleShortVersionString")
    if result.isSuccess {
        print("Output CLI v\(result.output)")
        exit(0)
    } else {
        print(result.errorOutput)
        print("Output CLI (removed from application bundle)")
        exit(1)
    }
}

// Initialize Output Object
let defaults = UserDefaults.standard
output.notifying = defaults.integer(forKey: "notifying")
output.section = defaults.integer(forKey: "section")
if let envVerbose = ProcessInfo.processInfo.environment["OUTPUT_VERBOSE"] {
    let envVerboseInt = Int(envVerbose) ?? -1
    if envVerboseInt > 0 {
        output.verbosity(level: (envVerboseInt + 1))
    } else if(envVerboseInt == 0) {
        output.quiet()
    }
}
if let envQuiet = ProcessInfo.processInfo.environment["OUTPUT_QUIET"] {
    if(!envQuiet.isEmpty && envQuiet != "0") {
        output.quiet()
    }
}

// Set Verbosity
var level: Int = 1
switch(verbosity) {
case .quiet:
    level = 0
case .verbose:
    level = 2
case .very_verbose:
    level = 3
default:
    break
}

switch(type) {
case .badge:
    output.badge(badge: msg, context: context)
case .line:
    output.outputln(message: msg, context: context, level: level)
case .notify:
    output.notify(message: msg, level: level)
case .inline:
    output.output(message: msg, context: context, level: level)
case .section:
    output.section(message: msg)
case .endsection:
    output.endSection()
}

defaults.set(output.section, forKey: "section")
defaults.set(output.notifying, forKey: "notifying")
exit(0)
