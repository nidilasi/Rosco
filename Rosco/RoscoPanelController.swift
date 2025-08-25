//
//  RoscoPanelController.swift
//  Rosco
//
//  Created by Evan Robertson on 16/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//

import AppKit

class RoscoPanelController : NSWindowController {

    override init(window: NSWindow?) {
        super.init(window: window)
        print("🏗️ RoscoPanelController initialized")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        print("🏗️ RoscoPanelController initialized from storyboard")
    }

    override func windowDidLoad() {
        super.windowDidLoad()
        print("🪟 RoscoPanelController windowDidLoad called")
        if let window = window as? NSPanel {
            print("🖥️ Setting up Rosco display window at lower-left corner")
            
            window.collectionBehavior = .canJoinAllSpaces
            window.setFrameOrigin(NSPoint(x: 20, y: 0)) // Bottom of screen
            
            window.backgroundColor = NSColor.black
            window.alphaValue = 0 // Start invisible, will show when music plays
            
            window.isFloatingPanel = true
            window.level = NSWindow.Level(rawValue: NSWindow.Level.normal.rawValue - 1)
            window.orderFront(nil)
            window.ignoresMouseEvents = true
            
            print("✅ Rosco display window created and positioned")
        } else {
            print("❌ Failed to get window as NSPanel")
        }
    }
}
