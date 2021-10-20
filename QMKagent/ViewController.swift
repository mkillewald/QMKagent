//
//  ViewController.swift
//  QMKagent
//
//  Created by Mike Killewald on 10/18/21.
//  Copyright © 2021 Mike Killewald. All rights reserved.
//

import Cocoa
import AppKit
import USBDeviceSwift

class ViewController: NSViewController {
    @IBOutlet weak var connectedDeviceLabel: NSTextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbConnected), name: .HIDDeviceConnected, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.usbDisconnected), name: .HIDDeviceDisconnected, object: nil)
        
        self.connectedDeviceLabel.stringValue = AppDelegate.connectedDevice?.deviceInfo.name ?? "No devices found."
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

// MARK: Storyboard instantiation
extension ViewController {
    
    static func freshController() -> ViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("ViewController")
        
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Why cant i find ViewController? - Check Main.storyboard")
        }
        
        return viewcontroller
    }
}

//MARK: Quit Button
extension ViewController {

    @IBAction func quitme(_ sender: NSButton) {
        NSApplication.shared.terminate(sender)
    }
}

//MARK: USBDeviceSwift
extension ViewController {
    
    @objc func usbConnected(notification: NSNotification) {
        
        // update UI
        DispatchQueue.main.async {
            self.connectedDeviceLabel.stringValue = AppDelegate.connectedDevice?.deviceInfo.name ?? "No devices found"
        }
    }
    
    @objc func usbDisconnected(notification: NSNotification) {
        
        // update UI
        DispatchQueue.main.async {
            if AppDelegate.connectedDevice == nil {
                self.connectedDeviceLabel.stringValue = "No devices found"
            }
        }
    }
}
