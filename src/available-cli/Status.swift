//
//  Status.swift
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
        super.init(label: StatusFlags.teams.label, status: from.active)
    }
}

class ZoomStatus: UserStatus {
    override var slug: String {
        return "zoom"
    }
    
    init(from: Zoom) {
        super.init(label: StatusFlags.zoom.label, status: from.active)
    }
}

class WebExStatus: UserStatus {
    override var slug: String {
        return "webex"
    }
    
    init(from: WebEx) {
        super.init(label: StatusFlags.webex.label, status: from.active)
    }
}

class GoToMeetingStatus: UserStatus {
    override var slug: String {
        return "gotomeeting"
    }
    
    init(from: GoToMeeting) {
        super.init(label: StatusFlags.gotomeeting.label, status: from.active)
    }
}

class PresentingStatus: UserStatus {
    override var slug: String {
        return "presentation"
    }
    
    init(from: NoDisplaySleep) {
        
        if(from.active) {
            super.init(label: StatusFlags.presenting.label, value: from.value)
        } else {
            super.init(label: StatusFlags.presenting.label, status: false)
        }
    }
}


class FileVaultStatus: UserStatus {
    override var slug: String {
        return "filevault"
    }
    
    init(from: System) {
        super.init(label: StatusFlags.filevault.label, status: from.isEncrypting)
    }
}

class BatteryPowerStatus: UserStatus {
    override var slug: String {
        return "battery"
    }
    
    init(from: System) {
        super.init(label: StatusFlags.power.label, status: !from.isAcPower)
    }
}

class MeteredNetworkStatus: UserStatus {
    override var slug: String {
        return "metered"
    }
    
    init(from: MeteredNetwork) {
        super.init(label: StatusFlags.metered.label, status: from.isMetered)
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
            super.init(label: StatusFlags.focus.label, status: false)
        } else {
            super.init(label: StatusFlags.focus.label, value: mode)
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
            super.init(label: StatusFlags.camera.label, status: false)
        } else {
            super.init(label: StatusFlags.camera.label, value: activeCamera)
        }
    }
}

