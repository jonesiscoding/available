//
//  main.swift
//  output-cli
//
//  Created by Aaron Jones on 3/21/23.
//

import Foundation
import Commands
import ArgumentParser

enum OutputType: String, CaseIterable, EnumerableFlag {
    case notify = "notify"
    case badge = "badge"
    case line = "line"
    case inline = "inline"
    case section = "section"
    case endsection = "endsection"
    
    var description: String {
        return self.rawValue
    }
    
    static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .notify:
            return "Displays message in cyan, followed by spacers. Typically used before an activity."
        case .badge:
            return "Displays inside uncolored brackets, such as [DONE]. Used after a --notify to indicate status."
        case .line:
            return "Displays message with a line feed."
        case .inline:
            return "Displays message inline, without a line feed."
        case .section:
            return "Displays message in magenta, and starts a section."
        case .endsection:
            return "Displays no message. Ends the current section."
        }
    }
}

extension OutputContext: EnumerableFlag {
    public static func help(for value: Self) -> ArgumentHelp? {
        switch value {
        case .success:
            return "Displays message in GREEN."
        case .error:
            return "Displays message in RED."
        case .message:
            return "Displays message in MAGENTA."
        case .info:
            return "Displays message in CYAN."
        case .normal:
             return "Displays message without color."
        }
    }
}

enum OutputVerbosity: Int, CaseIterable {
    case quiet = -1
    case verbose = 2
    case normal = 1
    case very_verbose = 3
}

@main
struct OutputCli: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "output-cli",
        abstract: "Allows for consistent output from CLI scripts, including status indicators, indentation sections, and colorized output.",
        version: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    )
    
    @Argument(help: "The message to output")
    var message: String = ""
    
    @Flag(exclusivity: .exclusive)
    var outputType: OutputType = .line
    
    @Flag(exclusivity: .exclusive)
    var context: OutputContext = OutputContext.normal
    
    @Option(help: "Logs message to the given file instead of displaying it. Logged messages are automatically prefixed with a timestamp.")
    var log: String?
    
    @Flag(name: .shortAndLong, help: "Display message even if OUTPUT_QUIET=1")
    var quiet: Bool = false
    
    @Flag(name: .shortAndLong, help: "Display message only if OUTPUT_VERBOSE=<number of flags>")
    var verbose: Int
    
    mutating func validate() throws {
        if(self.quiet) {
            self.verbose = OutputVerbosity.quiet.rawValue
        }
        
        if let _ = self.log {
            self.context = OutputContext.normal
        }
        
        if(self.outputType == .endsection) {
            self.message = ""
        }
        
        if(self.outputType == .badge && self.message.isEmpty) {
            if self.context == .normal {
                self.message = "OK"
            } else {
                self.message = self.context.rawValue.uppercased()
            }
        }
    }

    mutating func run() throws {
        let output: Output = Output(level: 1)
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
        
        let verbosity = self.verbose + 1
        
        if let logPath = self.log {
            let logUrl = URL(fileURLWithPath: logPath)
            try output.log(self.message, file: logUrl)
        } else {
            switch(self.outputType) {
            case .badge:
                output.badge(badge: self.message, context: context)
            case .line:
                output.outputln(message: self.message, context: context, level: verbosity)
            case .notify:
                output.notify(message: self.message, level: verbosity)
            case .inline:
                output.output(message: self.message, context: context, level: verbosity)
            case .section:
                output.section(message: self.message)
            case .endsection:
                output.endSection()
            }
        }
        
        defaults.set(output.section, forKey: "section")
        defaults.set(output.notifying, forKey: "notifying")
    }
}

struct RuntimeError: Error, CustomStringConvertible {
    var description: String
    
    init(_ description: String) {
        self.description = description
    }
}
