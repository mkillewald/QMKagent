//
//  AppDelegate.swift
//  QMKagent
//
//  Created by Mike Killewald on 10/18/21.
//  Copyright © 2021 Mike Killewald. All rights reserved.
//

import Cocoa
import AudioToolbox
import USBDeviceSwift

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    let popover = NSPopover()
    var eventMonitor: EventMonitor?
    let keychronQ1Monitor = HIDDeviceMonitor([
        HIDMonitorData(vendorId: 0x3434,
                       productId: 0x0100,
                       usagePage: 0xFF60,
                       usage: 0x61)
            ], reportSize: 32)  // this seems to be ignored and is 32 no matter what
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application        
        if let button = statusItem.button {
            button.image = NSImage(named:NSImage.Name("StatusBarIcon"))
            button.action = #selector(togglePopover(_:))
        }
        popover.contentViewController = ViewController.freshController()
        
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbConnected), name: .HIDDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbDisconnected), name: .HIDDeviceDisconnected, object: nil)
        
        // start Keychron Q1 daemon
        let keychronQ1Daemon = Thread(target: self.keychronQ1Monitor, selector:#selector(self.keychronQ1Monitor.start), object: nil)
        keychronQ1Daemon.start()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        if AppDelegate.connectedDevice != nil {
            AppDelegate.connectedDevice?.sendClear()
        }
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

}

//MARK: toggle popover
extension AppDelegate {
    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
          closePopover(sender: sender)
        } else {
          showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            eventMonitor?.start()
        }
    }

    func closePopover(sender: Any?) {
        popover.performClose(sender)
        eventMonitor?.stop()
    }
}


//MARK: USBDeviceSwift
extension AppDelegate {
    static var connectedDevice:QMKDevice?
    
    @objc func usbConnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let deviceInfo:HIDDevice = nobj["device"] as? HIDDevice else {
            return
        }
        
        let device = QMKDevice(deviceInfo)
        
        AppDelegate.connectedDevice = device
        
        AppDelegate.getSystemVolume()
        if (AppDelegate.isMuted != 0) {
            AppDelegate.connectedDevice?.sendRGBRange(r: 255, g: 0, b: 0, min: 0, max: UInt8(AppDelegate.volume * 12))
        } else {
            AppDelegate.connectedDevice?.sendRGBRange(r: 0, g: 255, b: 0, min: 0, max: UInt8(AppDelegate.volume * 12))
        }
    }
    
    @objc func usbDisconnected(notification: NSNotification) {
        guard let nobj = notification.object as? NSDictionary else {
            return
        }
        
        guard let id:String = nobj["id"] as? String else {
            return
        }
        
        if (id == AppDelegate.connectedDevice?.deviceInfo.id) {
            AppDelegate.connectedDevice = nil
        }
    }
}

//MARK: get system volume
extension AppDelegate {
    // based on https://stackoverflow.com/questions/27290751/using-audiotoolbox-from-swift-to-access-os-x-master-volume
    // and https://stackoverflow.com/questions/29062592/check-if-system-volume-is-muted
    
    static var isMuted: uint32 = 0
    static var volume = Float32(0.0)

    static func getSystemVolume() {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var defaultOutputDeviceIDSize = UInt32(MemoryLayout.size(ofValue: defaultOutputDeviceID))

        var getDefaultOutputDevicePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

        let _ = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &getDefaultOutputDevicePropertyAddress,
            0,
            nil,
            &defaultOutputDeviceIDSize,
            &defaultOutputDeviceID)

        var volumeSize = UInt32(MemoryLayout.size(ofValue: AppDelegate.volume))

        var volumePropertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwareServiceDeviceProperty_VirtualMasterVolume,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMaster)

        let _ = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &volumePropertyAddress,
            0,
            nil,
            &volumeSize,
            &AppDelegate.volume)

        var isMutedSize = UInt32(MemoryLayout.size(ofValue: AppDelegate.isMuted))

        var isMutedPropertyAddress = AudioObjectPropertyAddress(
            mSelector: AudioObjectPropertySelector(kAudioDevicePropertyMute),
            mScope: AudioObjectPropertyScope(kAudioObjectPropertyScopeOutput),
            mElement: AudioObjectPropertyElement(kAudioObjectPropertyElementMaster))

        let _ = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &isMutedPropertyAddress,
            0,
            nil,
            &isMutedSize,
            &AppDelegate.isMuted)
    }
}
