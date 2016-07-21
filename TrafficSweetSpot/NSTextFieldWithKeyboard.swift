//
//  NSTextFieldWithKeyboard.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/21/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa

@objc protocol UndoActionRespondable {
    func undo(sender: AnyObject)
}

@objc protocol RedoActionRespondable {
    func redo(sender: AnyObject)
}

class NSTextFieldWithKeyboard: NSTextField {
    
    private let commandKey = NSEventModifierFlags.CommandKeyMask.rawValue
    private let commandShiftKey = NSEventModifierFlags.CommandKeyMask.rawValue | NSEventModifierFlags.ShiftKeyMask.rawValue
    override func performKeyEquivalent(event: NSEvent) -> Bool {
        if event.type == NSEventType.KeyDown {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandKey {
                switch event.charactersIgnoringModifiers! {
                case "x":
                    // New Swift 2.2 #selector works for cut, copy, paste and select all
                    if NSApp.sendAction(#selector(NSText.cut(_:)), to:nil, from:self) { return true }
                case "c":
                    if NSApp.sendAction(#selector(NSText.copy(_:)), to:nil, from:self) { return true }
                case "v":
                    if NSApp.sendAction(#selector(NSText.paste(_:)), to:nil, from:self) { return true }
                case "z":
                    let undoSelector = #selector(UndoActionRespondable.undo(_:))
                    if NSApp.sendAction(undoSelector, to:nil, from:self) { return true }
                case "a":
                    if NSApp.sendAction(#selector(NSText.selectAll(_:)), to:nil, from:self) { return true }
                default:
                    break
                }
            }
            else if (event.modifierFlags.rawValue & NSEventModifierFlags.DeviceIndependentModifierFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    let redoSelector = #selector(RedoActionRespondable.redo(_:))
                    if NSApp.sendAction(redoSelector, to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(event)
    }
}
