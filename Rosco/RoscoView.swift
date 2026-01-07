//
//  RoscoView.swift
//  Rosco
//
//  Created by Evan Robertson on 16/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//

import AppKit

class RoscoView : NSVisualEffectView {
    
    @IBOutlet weak var titleLabel: NSTextField!
    @IBOutlet weak var artistNameLabel: NSTextField!

    private var trackSourceBundleId: String?
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didUpdateTrack(_:)), name: Notification.Name("RoscoUpdateTrack"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(notPlayingNotificationReceived(_:)), name: Notification.Name("RoscoNotPlaying"), object: nil)
        
        maskImage = NSImage(size: NSSize(width: 100, height: 20), flipped: false) { rect in

            let bezierPath = NSBezierPath()
            bezierPath.move(to: NSPoint(x: 0, y: 20))
            bezierPath.curve(to: NSPoint(x: 13, y: 20), controlPoint1: NSPoint(x: 0, y: 20), controlPoint2: NSPoint(x: -8, y: 20))
            bezierPath.curve(to: NSPoint(x: 58, y: 8), controlPoint1: NSPoint(x: 34, y: 20), controlPoint2: NSPoint(x: 43, y: 14))
            bezierPath.curve(to: NSPoint(x: 100, y: 0), controlPoint1: NSPoint(x: 73, y: 2), controlPoint2: NSPoint(x: 100, y: 0))
            bezierPath.line(to: NSPoint(x: 0, y: 0))
            bezierPath.line(to: NSPoint(x: 0, y: 20))
            bezierPath.close()
            bezierPath.fill()

            return true
        }
        maskImage?.capInsets = NSEdgeInsets(top: 0.0, left: 1.0, bottom: 0.0, right: 88.0)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func updateLayer() {
        
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Default to not playing
        if window != nil {
            notPlaying()
        }
    }

    func notPlaying() {
        self.trackSourceBundleId = nil

        DispatchQueue.main.async { [weak self] in
            guard let window = self?.window else { return }
            
            NSAnimationContext.current.duration = 0.5
            window.animator().alphaValue = 0
        }
    }

    @objc func didUpdateTrack(_ notification: NSNotification) {
        guard let track = notification.object as? Track else {
            notPlaying()
            return
        }

        self.trackSourceBundleId = notification.userInfo?["trackSourceBundleId"] as? String

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.titleLabel.stringValue = track.name.truncate(length: 48, trailing: "…")
            self.artistNameLabel.stringValue = track.artist.truncate(length: 48, trailing: "…")

            guard let window = self.window else { return }

            NSAnimationContext.current.duration = 0.5
            window.animator().alphaValue = 1.0
        }
    }

    @objc func notPlayingNotificationReceived(_ notification: NSNotification) {
        notPlaying()
    }

    override func mouseDown(with event: NSEvent) {
        switch AppSettings.shared.onClickAction {
        case .doNothing:
            return
        case .focusTrackSource:
            guard let bundleId = self.trackSourceBundleId else { return }
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                NSWorkspace.shared.open(appURL)
            }
        }
    }
}
