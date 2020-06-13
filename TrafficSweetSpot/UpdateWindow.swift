//
//  UpdateWindow.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/21/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa

class UpdateWindow: NSWindowController {
    override var windowNibName : NSNib.Name? {
        return NSNib.Name.init("UpdateWindow")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        self.window?.center()
        self.window?.title = "Update available for TrafficSweetSpot!"
        NSApp.activate(ignoringOtherApps: true)
        self.window?.makeKeyAndOrderFront(self)
    }

    @IBAction func downloadButtonClick(_ sender: AnyObject) {
        NSWorkspace.shared.open(URL(string: "https://github.com/fireph/TrafficSweetSpot/releases")!)
        self.window?.close()
    }
}
