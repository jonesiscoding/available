//
// Created by Aaron Jones on 9/30/22.
//

import Foundation
import Commands
import ArgumentParser

public enum OutputContext: String, CaseIterable {
    case success = "success"
    case error = "error"
    case message = "msg"
    case info = "info"
    case normal = "default"
}

public class Output {
    public var section: Int = 0
    public var level: Int
    private let line: String = "----------------------------------------------------------------------------"
    public var notifying: Int = 0
    public var dateFormat = "yyyy-MM-dd HH:mm:ss"
    private lazy var color: Bool = {
        let result = Commands.Bash.run("[ -n \"$TERM\" ] && [ \"$TERM\" != \"dumb\" ] && /usr/bin/tput -T$TERM colors")
        if result.isFailure {
          return false
        } else if result.output.isEmpty {
          return false
        } else if 8 >= Int(result.output) ?? 0 {
          return false
        }
        return true
    }()

    public init(level: Int) {
        self.level = level
    }
    
    // Contextual Functions
    
    public func blankln() {
        self.outputln(message: "")
    }

    public func successbg(_ badge: String) {
        self.badge(badge: badge, context: .success)
    }
    
    public func errorbg(_ badge: String) {
        self.badge(badge: badge, context: .error)
    }

    public func normalbg(_ badge: String) {
        self.badge(badge: badge)
    }
    
    public func error(_ message: String, level: Int = 1) {
        self.output(message: message, context: .error, level: level, terminator: "")
    }

    public func info(_ message: String, level: Int = 1) {
        self.output(message: message, context: .info, level: level, terminator: "")
    }

    public func msg(_ message: String, level: Int = 1) {
        self.output(message: message, context: .message, level: level, terminator: "")
    }

    public func normal(_ message: String, level: Int = 1) {
        self.output(message: message, context: .normal, level: level, terminator: "")
    }

    public func success(_ message: String, level: Int = 1) {
        self.output(message: message, context: .success, level: level, terminator: "")
    }

    public func errorln(_ message: String, level: Int = 1) {
        self.outputln(message: message, context: .error, level: level)
    }

    public func infoln(_ message: String, level: Int = 1) {
        self.outputln(message: message, context: .info, level: level)
    }

    public func msgln(_ message: String, level: Int = 1) {
        self.outputln(message: message, context: .message, level: level)
    }

    public func normalln(_ message: String, level: Int = 1) {
        self.outputln(message: message, context: .normal, level: level)
    }

    public func successln(_ message: String, level: Int = 1) {
        self.outputln(message: message, context: .success, level: level)
    }
    
    // Utility Functions
    
    public func done() {
        successbg("DONE")
    }

    public func quiet() {
        self.level = -1
    }

    public func verbosity(level: Int) {
        self.level = level
    }

    public func section(message: String = "Section") {
        self.msgln(message)
        self.section = self.section + 1
    }

    public func endSection() {
      self.section = self.section - 1
      if self.section < 0 {
        self.section = 0
      }
    }

    public func notify(message: String, level: Int = 1) {
        if self.level >= level {
            self.notifying = level
            let output = self.color ? message.style(.cyan) : message
            pr(output.padding(toLength: (76 - (self.section * 2)), withPad: ".", startingAt: 0), terminator: " ")
        }
    }
    
    public func log(_ message: String, file: URL) throws {
        let output = self.timestamp(message)
        let fm = FileManager()
        // Convert to Data
        guard let data = ("\(output)\n").data(using: String.Encoding.utf8) else { return }
        if fm.fileExists(atPath: file.path) {
            let fileHandle = try FileHandle(forWritingTo: file)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
        } else {
            var isDir : ObjCBool = true
            if(!fm.fileExists(atPath: file.deletingLastPathComponent().path, isDirectory: &isDir)) {
                try fm.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
            }
            
            try data.write(to: file, options: .atomicWrite)
        }
    }
    
    // Generic Functions
    
    public func badge(badge: String, context: OutputContext = .normal) {
        if self.level >= self.notifying && self.notifying > 0 {
            var output: String = badge
            if(self.color) {
                switch(context) {
                case OutputContext.success:
                    output = badge.style(.green)
                case OutputContext.error:
                    output = badge.style(.red)
                case OutputContext.message:
                    output = badge.style(.magenta)
                case OutputContext.info:
                    output = badge.style(.cyan)
                default:
                    break
                }
            }
            print("[\(output)]")
            self.notifying = 0
        }
    }
    
    public func output(message: String, context: OutputContext = .normal, level: Int = 1, terminator: String = " ") {
        if self.notifying >= self.level {
            switch(context) {
            case OutputContext.success:
                self.badge(badge: "SUCCESS", context: .success)
            case OutputContext.error:
                self.badge(badge: "ERROR", context: .error)
            case OutputContext.message:
                self.badge(badge: "SEE BELOW", context: .message)
            case OutputContext.info:
                self.badge(badge: "SEE BELOW", context: .info)
            default:
                self.badge(badge: "SEE BELOW", context: .normal)
            }
        }

        if self.level >= level {
            var output: String = message
            if(self.color) {
                switch(context) {
                case OutputContext.success:
                    output = message.style(.green)
                case OutputContext.error:
                    output = message.style(.red)
                case OutputContext.message:
                    output = message.style(.magenta)
                case OutputContext.info:
                    output = message.style(.cyan)
                default:
                    break
                }
            }
            
            pr(output, separator: " ", terminator: terminator)
        }
    }
    
    public func outputln(message: String, context: OutputContext = .normal, level: Int = 1) {
        self.output(message: message, context: context, level: level, terminator: "\n")
    }
    
    // Private Functions

    private func pr(_ string: String, separator: String = " ", terminator: String = "\n") {
        if self.section > 0 {
          let repeated = String(repeating: " ", count: (self.section * 2))
          print(repeated, terminator: "")
        }

        print(string, separator: separator, terminator: terminator)
    }
    
    private func timestamp(_ message: String) -> String {
        // Get the Date Handled
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timestamp = formatter.string(from: date)
        
        // Break Message Into Parts, Add Timestamp
        let iLines = message.components(separatedBy: "\n")
        let oLines: [String] = iLines.map { "\(timestamp)  \($0)" }
        
        // Return as single string
        return oLines.joined(separator: "\n")
    }
}
