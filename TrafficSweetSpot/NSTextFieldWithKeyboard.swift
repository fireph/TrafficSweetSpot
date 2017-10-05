//
//  NSTextFieldWithKeyboard.swift
//  TrafficSweetSpot
//
//  Created by Freddie Meyer on 7/21/16.
//  Copyright © 2016 Freddie Meyer. All rights reserved.
//

import Cocoa

@objc protocol UndoActionRespondable {
    func undo(_ sender: AnyObject)
}

@objc protocol RedoActionRespondable {
    func redo(_ sender: AnyObject)
}

class NSTextFieldWithKeyboard: NSTextField {
    
    fileprivate let commandKey = NSEventModifierFlags.command.rawValue
    fileprivate let commandShiftKey = NSEventModifierFlags.command.rawValue | NSEventModifierFlags.shift.rawValue
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.type == NSEventType.keyDown {
            if (event.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == commandKey {
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
            else if (event.modifierFlags.rawValue & NSEventModifierFlags.deviceIndependentFlagsMask.rawValue) == commandShiftKey {
                if event.charactersIgnoringModifiers == "Z" {
                    let redoSelector = #selector(RedoActionRespondable.redo(_:))
                    if NSApp.sendAction(redoSelector, to:nil, from:self) { return true }
                }
            }
        }
        return super.performKeyEquivalent(with: event)
    }
}
