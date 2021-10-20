//
//  QMKDevice.swift
//  QMKagent
//
//  Based on RaceflightControllerHIDExample by Artem Hruzd.
//  https://github.com/Arti3DPlayer/USBDeviceSwift/tree/master/RaceflightControllerHIDExample
//
//  Created by Mike Killewald on 10/18/21.
//  Copyright © 2021 Mike Killewald. All rights reserved.
//

import Cocoa
import USBDeviceSwift

class QMKDevice: NSObject {
    let deviceInfo:HIDDevice
    
    required init(_ deviceInfo:HIDDevice) {
        self.deviceInfo = deviceInfo
    }
    
    func sendRGBRange(r: UInt8, g: UInt8, b: UInt8, min: UInt8, max: UInt8) {
        self.write(Data([128, 5, 0, 0, 0, r, g, b, min, max]))
    }
    
    func sendClear() {
        self.write(Data([129]))
    }
    
    func write(_ data: Data) {
        var bytesArray = [UInt8](data)
        
//        print("Received Data: \([UInt8](data))")
        
        let reportId:UInt8 = 0
        bytesArray.insert(reportId, at: 0)
        
//        print("Bytes Array: \(bytesArray)")
        
        if (bytesArray.count > self.deviceInfo.reportSize) {
            print("Output data too large for USB report")
            return
        }
        
        let padding = self.deviceInfo.reportSize - bytesArray.count
        if padding > 0 {
            for _ in 1...padding {
                bytesArray.append(0)
            }
        }
        
//        print("bytesArray size: \(bytesArray.count)")

        let correctData = Data(bytes: bytesArray, count: self.deviceInfo.reportSize)
        
//        print("Report Size: \(self.deviceInfo.reportSize)")
//        print("Correct Data: (\(correctData.count) bytes) \([UInt8](correctData))")
        
        IOHIDDeviceSetReport(
            self.deviceInfo.device,
            kIOHIDReportTypeOutput,
            CFIndex(reportId),
            (correctData as NSData).bytes.bindMemory(to: UInt8.self, capacity: correctData.count),
            correctData.count
        )
    }
}
