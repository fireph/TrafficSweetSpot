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
    
    var delegate: PreferencesWindowDelegate?

    override var windowNibName : String! {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.title = "Preferences"
        NSApp.activateIgnoringOtherApps(true)
        let defaults = NSUserDefaults.standardUserDefaults()
        if let apiKeyVal = defaults.stringForKey("apiKey") {
            apiKeyInput.stringValue = apiKeyVal
        }
        if let originVal = defaults.stringForKey("origin") {
            originInput.stringValue = originVal
        }
        if let destVal = defaults.stringForKey("dest") {
            destInput.stringValue = destVal
        }
        if let cacheVal = defaults.stringForKey("cache") {
            cacheInput.stringValue = cacheVal
        }
    }

    @IBAction func saveClicked(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(apiKeyInput.stringValue, forKey: "apiKey")
        defaults.setValue(originInput.stringValue, forKey: "origin")
        defaults.setValue(destInput.stringValue, forKey: "dest")
        defaults.setValue(cacheInput.stringValue, forKey: "cache")
        defaults.synchronize()
        delegate?.preferencesDidUpdate()
        self.window?.close()
    }
}
