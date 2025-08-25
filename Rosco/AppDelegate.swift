//
//  AppDelegate.swift
//  Rosco
//
//  Created by Evan Robertson on 16/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var systemDefaultStyleMenuItem: NSMenuItem!
    @IBOutlet weak var lightMenuItem: NSMenuItem!
    @IBOutlet weak var darkMenuItem: NSMenuItem!
    
    let styleKey = "RoscoStyle";
    
    let statusItem = NSStatusBar.system.statusItem(withLength:NSStatusItem.squareLength)
    
    var nowPlayingService: NowPlayingService?
    var displayWindowController: RoscoPanelController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        // Setup status bar item
        if let button = statusItem.button {
            if let image = NSImage(named: "status_bar_icon") {
                image.isTemplate = true
                button.image = image
                print("✅ Status bar icon loaded successfully")
            } else {
                // Fallback to a system icon if our icon fails to load
                button.title = "🎵"
                print("⚠️ Failed to load status_bar_icon, using fallback")
            }
        }
        
        statusItem.menu = menu
        
        // Hide first two menu items if they exist
        if menu.items.count > 1 {
            menu.items[0].isHidden = true
            menu.items[1].isHidden = true
        }
        
        // Initialize display window from storyboard
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        displayWindowController = storyboard.instantiateController(withIdentifier: "NSWindowController-B8D-0N-5wS") as? RoscoPanelController
        print("🖥️ Display window controller initialized")
        
        // Check media permissions status before initializing
        checkMediaPermissions()
        
        // Initialize now playing service
        nowPlayingService = NowPlayingService()
        print("🎵 NowPlayingService initialized")
        
        // Set the display style from defaults
        let appearanceName = UserDefaults.standard.object(forKey: styleKey) as? NSAppearance.Name
        setStyleMenuStates(appearanceName: appearanceName)
        setAppStyle(appearanceName: appearanceName)
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func getRoscoView() -> RoscoView? {
        if let window = NSApplication.shared.windows.first(where: { $0.contentView is RoscoView }),
        let roscoView = window.contentView as? RoscoView {
            return roscoView
        }
        
        return nil
    }
        
    func setStyleMenuStates(appearanceName: NSAppearance.Name?) {
        systemDefaultStyleMenuItem.state = appearanceName == nil ? .on : .off
        lightMenuItem.state = appearanceName == NSAppearance.Name.aqua ? .on : .off
        darkMenuItem.state = appearanceName == NSAppearance.Name.darkAqua ? .on : .off
    }
    
    func setAppStyle(appearanceName: NSAppearance.Name?) {
        var appearance: NSAppearance?
        
        if let appearanceName = appearanceName {
            appearance = NSAppearance(named: appearanceName)
            UserDefaults.standard.set(appearanceName, forKey: styleKey)
        } else {
            UserDefaults.standard.removeObject(forKey: styleKey)
        }
        
        if let roscoView = getRoscoView() {
            roscoView.appearance = appearance
       }
    }

    @IBAction func selectSystemDefaultStyle(_ sender: Any) {
        setStyleMenuStates(appearanceName: nil)
        setAppStyle(appearanceName: nil)
    }
    
    @IBAction func selectLightStyle(_ sender: Any) {
        let appearanceName = NSAppearance.Name.aqua
        setStyleMenuStates(appearanceName: appearanceName)
        setAppStyle(appearanceName: appearanceName)
    }
    
    @IBAction func selectDarkStyle(_ sender: Any) {
        let appearanceName = NSAppearance.Name.darkAqua
        setStyleMenuStates(appearanceName: appearanceName)
        setAppStyle(appearanceName: appearanceName)
    }
    
    func checkMediaPermissions() {
        print("🔐 Checking media permissions and code signing status...")
        
        // Check if we're properly signed
        let bundlePath = Bundle.main.bundlePath
        print("📁 App bundle path: \(bundlePath)")
        
        // Try to determine permission status
        if #available(macOS 14.0, *) {
            print("📱 Running on macOS 14.0+ - checking privacy permissions")
            print("⚠️ Note: adhoc signed apps may not trigger permission dialogs")
            print("💡 For full functionality on macOS 15.4+, this app needs:")
            print("   1. Valid Developer ID signature (not adhoc)")
            print("   2. User must manually enable in System Settings > Privacy & Security > Media & Apple Music")
        } else {
            print("📱 Running on older macOS - should work without explicit permissions")
        }
        
        // Check the current entitlements
        print("🔑 App entitlements should include:")
        print("   - com.apple.security.personal-information.media-library = true")
        print("   - com.apple.security.media-devices.access = true")
        
        // Test media access directly
        testMediaAccess()
    }
    
    func testMediaAccess() {
        print("🧪 Testing MediaRemote access...")
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))
        
        if let bundle = bundle,
           let getInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) {
            print("✅ MediaRemote framework accessible")
            
            typealias GetInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
            let getInfo = unsafeBitCast(getInfoPointer, to: GetInfoFunction.self)
            
            getInfo(DispatchQueue.main) { info in
                if info.isEmpty {
                    print("❌ MediaRemote returned empty info - permission likely denied")
                    print("📋 Manual steps to fix:")
                    print("   1. Open System Settings")
                    print("   2. Go to Privacy & Security > Media & Apple Music")
                    print("   3. Enable Rosco in the list")
                    print("   4. Restart Rosco")
                } else {
                    print("✅ MediaRemote access working - found \(info.count) info items")
                }
            }
        } else {
            print("❌ Cannot access MediaRemote framework")
        }
    }
}

