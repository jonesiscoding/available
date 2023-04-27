//
//  Status.swift
//  available-cli
//
//  Created by Aaron Jones on 3/14/23.
//

import Foundation

class UserStatus: CustomStringConvertible {
    var description: String {
        return self.value
    }
    
    var slug: String {
        return self.label.replacingOccurrences(of: "Active", with: "").trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: " ", with: "-").lowercased()
    }
    
    var label: String
    var status: Bool
    var value: String
    
    init(label: String, status: Bool) {
        self.label = label
        self.status = status
        self.value = status ? "True" : "False"
    }
    
    init(label: String, value: String) {
        self.label = label
        self.value = value
        self.status = (self.value.isEmpty || self.value == "False") ? false : true
    }
}

class TeamsStatus: UserStatus {
    override var slug: String {
        return "teams"
    }
    
    init(from: Teams) {
        super.init(label: "Teams Active", status: from.active)
    }
}

class ZoomStatus: UserStatus {
    override var slug: String {
        return "zoom"
    }
    
    init(from: Zoom) {
        super.init(label: "Zoom Active", status: from.active)
    }
}

class WebExStatus: UserStatus {
    override var slug: String {
        return "webex"
    }
    
    init(from: WebEx) {
        super.init(label: "WebEx Active", status: from.active)
    }
}

class GoToMeetingStatus: UserStatus {
    override var slug: String {
        return "gotomeeting"
    }
    
    init(from: GoToMeeting) {
        super.init(label: "GoToMeeting Active", status: from.active)
    }
}

class PresentingStatus: UserStatus {
    override var slug: String {
        return "presentation"
    }
    
    init(from: NoDisplaySleep) {
        
        if(from.active) {
            super.init(label: "Presentation Mode", value: from.value)
        } else {
            super.init(label: "Presentation Mode", status: false)
        }
    }
}


class FileVaultStatus: UserStatus {
    override var slug: String {
        return "filevault"
    }
    
    init(from: System) {
        super.init(label: "FileVault Encrypting", status: from.isEncrypting)
    }
}

class BatteryPowerStatus: UserStatus {
    override var slug: String {
        return "battery"
    }
    
    init(from: System) {
        super.init(label: "Battery Power", status: !from.isAcPower)
    }
}

class MeteredNetworkStatus: UserStatus {
    override var slug: String {
        return "metered"
    }
    
    init(from: MeteredNetwork) {
        super.init(label: "Metered Network", status: from.isMetered)
    }
}


class FocusModeStatus: UserStatus {
    override var slug: String {
        return "focus-\(self.value)"
    }
    
    init(from: Focus, ignore: [String]) throws {
        var mode = try from.getMode()
        for iMode in ignore {
            if(iMode == mode) {
                mode = ""
            }
        }
        
        if(mode.isEmpty) {
            super.init(label: "Focus Mode", status: false)
        } else {
            super.init(label: "Focus Mode", value: mode)
        }
    }
}

class CameraStatus: UserStatus {
    override var slug: String {
        let camera = self.value.replacingOccurrences(of: " ", with: "-").lowercased()
        return "camera-\(camera)"
    }
    
    init(from: [Camera]) throws {
        var activeCamera: String = ""
        for camera in from {
            if camera.isOn {
                activeCamera = camera.name ?? "Unknown"
            }
        }
        
        if(activeCamera.isEmpty) {
            super.init(label: "Camera Active", status: false)
        } else {
            super.init(label: "Camera Active", value: activeCamera)
        }
    }
}

