//
//  MediaApplication.swift
//  QMK Agent
//
//  Based on MediaApplication class by Chris Rees (Serneum)
//  https://gist.github.com/Serneum/b0ed0f75f3d0c6e4058a
//
//  Created by Mike Killewald on 10/18/21
//  Copyright © 2021 Mike Killewald. All rights reserved.
//

import Cocoa

extension Int {
    var boolValue: Bool { return self != 0 }
}

class MediaApplication: NSApplication {
    var previousVolume = Float32(99.0)
    
    override func sendEvent(_ event: NSEvent) {
        if (event.type == .systemDefined && event.subtype.rawValue == 8) {
            let keyCode = ((event.data1 & 0xFFFF0000) >> 16)
            let keyFlags = (event.data1 & 0x0000FFFF)
            // Get the key state. 0xA is KeyDown, OxB is KeyUp
            let keyState = (((keyFlags & 0xFF00) >> 8)) == 0xA
            let keyRepeat = (keyFlags & 0x1)
            
            mediaKeyEvent(key: Int32(keyCode), state: keyState, keyRepeat: keyRepeat.boolValue)
        }
     
        super.sendEvent(event)
    }
    
    func getSystemVolume() {
        AppDelegate.getSystemVolume()
        if self.previousVolume == 99.0 {
            print("previousVolume inited")
            self.previousVolume = AppDelegate.volume
        }
    }
    
    func mediaKeyEvent(key: Int32, state: Bool, keyRepeat: Bool) {
        // Only send events on KeyDown. Without this check, these events will happen twice
        if (state) {            
            switch(key) {
            case NX_KEYTYPE_SOUND_UP:
                self.getSystemVolume()
                if AppDelegate.volume < self.previousVolume {
                    AppDelegate.volume = self.previousVolume
                }
                if AppDelegate.connectedDevice != nil {
                    AppDelegate.connectedDevice?.sendRGBRange(r: 0, g: 255, b: 0, min: 0, max: UInt8(12 * AppDelegate.volume))
                    previousVolume = AppDelegate.volume
                }
                break
            case NX_KEYTYPE_SOUND_DOWN:
                self.getSystemVolume()
                if AppDelegate.volume > self.previousVolume {
                    AppDelegate.volume = self.previousVolume
                }
                if AppDelegate.connectedDevice != nil {
                    if AppDelegate.isMuted != 0 {
                        AppDelegate.connectedDevice?.sendRGBRange(r: 255, g: 0, b: 0, min: 0, max: UInt8(12 * AppDelegate.volume))
                    } else {
                        AppDelegate.connectedDevice?.sendRGBRange(r: 0, g: 255, b: 0, min: 0, max: UInt8(12 * AppDelegate.volume))
                    }
                    self.previousVolume = AppDelegate.volume
                }
                break
            case NX_KEYTYPE_MUTE:
                self.getSystemVolume()
                if AppDelegate.volume != self.previousVolume {
                    AppDelegate.volume = self.previousVolume
                }
                if AppDelegate.connectedDevice != nil {
                    if AppDelegate.isMuted != 0 {
                        AppDelegate.connectedDevice?.sendRGBRange(r: 255, g: 0, b: 0, min: 0, max: UInt8(12 * AppDelegate.volume))
                    } else {
                        AppDelegate.connectedDevice?.sendRGBRange(r: 0, g: 255, b: 0, min: 0, max: UInt8(12 * AppDelegate.volume))
                    }
                    self.previousVolume = AppDelegate.volume
                }
                break
            default:
                break
            }
        }
    }
}
