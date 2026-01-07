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
        super.windowDidLoad()

        guard let panel = window as? NSPanel else { return }

        panel.collectionBehavior = .canJoinAllSpaces
        panel.setFrameOrigin(NSPoint(x: 0, y: 0))

        panel.backgroundColor = .black
        panel.alphaValue = 0
        panel.isOpaque = false

        panel.isFloatingPanel = true
        panel.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
        panel.orderFront(nil)
        panel.ignoresMouseEvents = false

        // Ensure animations are enabled
        panel.animationBehavior = .default
    }
}
