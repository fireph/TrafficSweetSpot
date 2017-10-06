//
//  PreferencesWindow.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/19/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa

protocol PreferencesWindowDelegate {
    func preferencesDidUpdate()
}

class PreferencesWindow: NSWindowController {
    @IBOutlet weak var apiKeyInput: NSTextField!
    @IBOutlet weak var originInput: NSTextField!
    @IBOutlet weak var destInput: NSTextField!
    @IBOutlet weak var cacheInput: NSPopUpButton!
    @IBOutlet weak var notificationsCheckbox: NSButton!
    @IBOutlet weak var notificationsTimeSlider: NSSlider!
    @IBOutlet weak var notificationsTimeLabel: NSTextField!
    @IBOutlet weak var checkForUpdatesCheckBox: NSButton!
    
    var delegate: PreferencesWindowDelegate?

    override var windowNibName : NSNib.Name? {
        return NSNib.Name.init("PreferencesWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.title = "Preferences"
        NSApp.activate(ignoringOtherApps: true)
        let defaults = UserDefaults.standard
        if let apiKeyVal = defaults.string(forKey: "apiKey") {
            apiKeyInput.stringValue = apiKeyVal
        }
        if let originVal = defaults.string(forKey: "origin") {
            originInput.stringValue = originVal
        }
        if let destVal = defaults.string(forKey: "dest") {
            destInput.stringValue = destVal
        }
        if let cacheVal = defaults.string(forKey: "cache") {
            cacheInput.stringValue = cacheVal
        }
        if let notificationsEnabledVal = defaults.string(forKey: "notificationsEnabled") {
            notificationsCheckbox.stringValue = notificationsEnabledVal
        }
        if let notificationsTimeVal = defaults.string(forKey: "notificationsTime") {
            notificationsTimeSlider.stringValue = notificationsTimeVal
        }
        if let checkForUpdatesVal = defaults.string(forKey: "checkForUpdates") {
            checkForUpdatesCheckBox.stringValue = checkForUpdatesVal
        }
    }
    @IBAction func onSliderUpdate(_ sender: Any) {
        notificationsTimeSlider.integerValue = Int(notificationsTimeSlider.floatValue.rounded())
        let value = notificationsTimeSlider.integerValue
        var hours = String(value / 60)
        if (hours.count < 2) {
            hours = "0" + hours
        }
        var minutes = String(value % 60)
        if (minutes.count < 2) {
            minutes = "0" + minutes
        }
        notificationsTimeLabel.stringValue = hours + ":" + minutes
    }
    
    @IBAction func saveClicked(_ sender: AnyObject) {
        let defaults = UserDefaults.standard
        defaults.setValue(apiKeyInput.stringValue, forKey: "apiKey")
        defaults.setValue(originInput.stringValue, forKey: "origin")
        defaults.setValue(destInput.stringValue, forKey: "dest")
        defaults.setValue(cacheInput.stringValue, forKey: "cache")
        defaults.setValue(notificationsCheckbox.stringValue, forKey: "notificationsEnabled")
        defaults.setValue(notificationsTimeSlider.stringValue, forKey: "notificationsTime")
        defaults.setValue(checkForUpdatesCheckBox.stringValue, forKey: "checkForUpdates")
        defaults.synchronize()
        delegate?.preferencesDidUpdate()
        self.window?.close()
    }
}
