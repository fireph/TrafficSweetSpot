//
//  UpdateWindow.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/21/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa

class UpdateWindow: NSWindowController {
    override var windowNibName : String! {
        return "UpdateWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        self.window?.title = "Update available for TrafficSweetSpot!"
        NSApp.activateIgnoringOtherApps(true)
    }

    @IBAction func downloadButtonClick(sender: AnyObject) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: "https://github.com/DungFu/TrafficSweetSpot/releases")!)
        self.window?.close()
    }
}
