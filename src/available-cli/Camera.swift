//
//  Camera.swift
//  com.econoprint.available
//
//  Created by Aaron Jones on 3/10/23.
//

import Foundation
import CoreMediaIO
import Foundation
import SystemConfiguration
import SwiftUI

/// Retrieves Camera Status (on/off).  Note that  kCMIODevicePropertyDeviceIsRunningSomewhere is the key here
/// - Authors:  From Nudge Utils: https://github.com/macadmins/nudge/blob/main/Nudge/Utilities/Utils.swift
///            Nudge Developer states: https://stackoverflow.com/questions/37470201/how-can-i-tell-if-the-camera-is-in-use-by-another-process
///               Led Nudge Developer to: https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm
///               Complete credit to: https://github.com/ttimpe/camera-usage-detector-mac/blob/845df180f9d19463e8fd382277e2f61d88ca7d5d/CameraUsage/CameraUsageController.swift
///
struct Camera {
    var id: CMIOObjectID
    var name: String? {
        get {
            var address:CMIOObjectPropertyAddress = CMIOObjectPropertyAddress(
                mSelector:CMIOObjectPropertySelector(kCMIOObjectPropertyName),
                mScope:CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
                mElement:CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain))

            var name:CFString? = nil
            let propsize:UInt32 = UInt32(MemoryLayout<CFString?>.size)
            var dataUsed: UInt32 = 0

            let result:OSStatus = CMIOObjectGetPropertyData(self.id, &address, 0, nil, propsize, &dataUsed, &name)
            if (result != 0) {
                return ""
            }

            return name as String?
        }
    }
    var isOn: Bool {
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIODevicePropertyDeviceIsRunningSomewhere),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeWildcard),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementWildcard)
        )

        
        var isUsed = false
        
        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(self.id, &opa, 0, nil, &dataSize)
        if result == OSStatus(kCMIOHardwareNoError) {
            if let data = malloc(Int(dataSize)) {
                result = CMIOObjectGetPropertyData(self.id, &opa, 0, nil, dataSize, &dataUsed, data)
                let on = data.assumingMemoryBound(to: UInt8.self)
                isUsed = on.pointee != 0
            }
        }

        return isUsed
    }
}

/// Array of camera objects.
/// - Authors:  From Nudge Utils: https://github.com/macadmins/nudge/blob/main/Nudge/Utilities/Utils.swift
///            Nudge Developer states: https://stackoverflow.com/questions/37470201/how-can-i-tell-if-the-camera-is-in-use-by-another-process
///               Led Nudge Developer to: https://github.com/antonfisher/go-media-devices-state/blob/main/pkg/camera/camera_darwin.mm
///               Complete credit to: https://github.com/ttimpe/camera-usage-detector-mac/blob/845df180f9d19463e8fd382277e2f61d88ca7d5d/CameraUsage/CameraUsageController.swift
///
var cameras: [Camera]  {
    get {
        var innerArray :[Camera] = []
        var opa = CMIOObjectPropertyAddress(
            mSelector: CMIOObjectPropertySelector(kCMIOHardwarePropertyDevices),
            mScope: CMIOObjectPropertyScope(kCMIOObjectPropertyScopeGlobal),
            mElement: CMIOObjectPropertyElement(kCMIOObjectPropertyElementMain)
        )

        var dataSize: UInt32 = 0
        var dataUsed: UInt32 = 0
        var result = CMIOObjectGetPropertyDataSize(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, &dataSize)
        var devices: UnsafeMutableRawPointer?

        repeat {
            if devices != nil {
                free(devices)
                devices = nil
            }

            devices = malloc(Int(dataSize))
            result = CMIOObjectGetPropertyData(CMIOObjectID(kCMIOObjectSystemObject), &opa, 0, nil, dataSize, &dataUsed, devices)
        } while result == OSStatus(kCMIOHardwareBadPropertySizeError)


        if let devices = devices {
            for offset in stride(from: 0, to: dataSize, by: MemoryLayout<CMIOObjectID>.size) {
                let current = devices.advanced(by: Int(offset)).assumingMemoryBound(to: CMIOObjectID.self)
                innerArray.append(Camera(id: current.pointee))
            }
        }

        free(devices)


        return innerArray
    }
}
