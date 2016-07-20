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
        apiKeyInput.stringValue = defaults.stringForKey("apiKey")!
        originInput.stringValue = defaults.stringForKey("origin")!
        destInput.stringValue = defaults.stringForKey("dest")!
    }

    @IBAction func saveClicked(sender: AnyObject) {
        let defaults = NSUserDefaults.standardUserDefaults()
        defaults.setValue(apiKeyInput.stringValue, forKey: "apiKey")
        defaults.setValue(originInput.stringValue, forKey: "origin")
        defaults.setValue(destInput.stringValue, forKey: "dest")
        delegate?.preferencesDidUpdate()
        self.window?.close()
    }
}
