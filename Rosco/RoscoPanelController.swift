//
//  RoscoPanelController.swift
//  Rosco
//
//  Created by Evan Robertson on 16/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//

import AppKit

class RoscoPanelController : NSWindowController {

    override func windowDidLoad() {
        if let window = window as? NSPanel {
            window.collectionBehavior = .canJoinAllSpaces
            window.setFrameOrigin(NSPoint(x: 0, y: 0))
            
            window.backgroundColor = NSColor.black
            window.alphaValue = 0
//            window.backgroundColor = NSColor.black.withAlphaComponent(0.5)
            
            window.isFloatingPanel = true
            window.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
            window.orderFront(nil)
            window.ignoresMouseEvents = true
        }
    }
}
