//
//  Display.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import Commands

extension String {
    var lines: [String] {
        var result: [String] = []
        enumerateLines { line, _ in result.append(line) }
        return result
    }
}

/// Retrieves Display Sleep Assertions, ignoring assertions without the process, any coreaudiod processes, and Video Wake Lock that is just Chrome playing a YouTube video in the foreground.
///
/// - Authors:  Credit (PR 268) (https://github.com/Installomator/Installomator) Copyright 2020 Armin Briegel
///            Adapted to Swift by Aaron Jones <am@jonesiscoding.com>
/// - SeeAlso:  https://developer.apple.com/documentation/iokit/iopmlib_h/iopmassertiontypes
///
struct NoDisplaySleep {
    var value: String {
        let result = Commands.Bash.run("/usr/bin/pmset -g assertions")
        if result.isSuccess {
            for line in result.output.lines {
                if(line.contains("NoDisplaySleepAssertion") || line.contains("PreventUserIdleDisplaySleep")) {
                    let lineRest = line.replacingOccurrences(of: "NoDisplaySleepAssertion", with: "").replacingOccurrences(of: "PreventUserIdleDisplaySleep", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    if(!lineRest.contains("coreaudiod") && !lineRest.contains("Video Wake Lock") && lineRest != "0" && lineRest != "1") {
                        if #available(macOS 13.0, *) {
                            let keyAndValue = /pid [0-9]+\(([^\)]+)\):/
                            if let match = lineRest.firstMatch(of: keyAndValue) {
                                return String(match.1)
                            }
                        } else {
                            let perlResult = Commands.Bash.run("perl -nle 'm/pid [0-9]+\\(([^\\)]+)\\)/; print $1'")
                            if(perlResult.isSuccess) {
                                return perlResult.output
                            }
                        }
                        
                        return lineRest
                    }
                }
            }
        }
        
        return ""
    }
    
    var active: Bool {
        return !self.value.isEmpty
    }
}
