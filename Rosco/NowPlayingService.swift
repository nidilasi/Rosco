//
//  NowPlayingService.swift
//  Rosco
//
//  Created by Evan Robertson on 19/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//
//  NOTE: "Operation not permitted" errors are expected on modern macOS
//  due to privacy restrictions. The app should still function for basic
//  track detection despite these warnings.
//
import Cocoa

class NowPlayingService {
    typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
    typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
    
    typealias MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction = @convention(c) (DispatchQueue, @escaping (Bool) -> Void) -> Void
    var MRMediaRemoteGetNowPlayingApplicationIsPlaying : MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction?

    var MRMediaRemoteGetNowPlayingInfo : MRMediaRemoteGetNowPlayingInfoFunction?
    var lastTrack: Track?
    var isPlaying: Bool = false
    
    init () {
        print("🎵 Initializing NowPlayingService...")
        
        // Load framework
        guard let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework")) else {
            print("❌ Failed to load MediaRemote framework")
            return
        }
        print("✅ MediaRemote framework loaded successfully")

        guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else {
            print("❌ Failed to get function pointer: MRMediaRemoteRegisterForNowPlayingNotifications")
            return
        }
        print("✅ Got MRMediaRemoteRegisterForNowPlayingNotifications function pointer")

        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main)
        print("✅ Registered for now playing notifications")

        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            print("❌ Failed to get function pointer: MRMediaRemoteGetNowPlayingInfo")
            return
        }
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        print("✅ Got MRMediaRemoteGetNowPlayingInfo function pointer")
        
    
        // Check if music is already playing
        guard let MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingApplicationIsPlaying" as CFString) else {
            print("❌ Failed to get function pointer: MRMediaRemoteGetNowPlayingApplicationIsPlaying")
            return
        }
        MRMediaRemoteGetNowPlayingApplicationIsPlaying = unsafeBitCast(MRMediaRemoteGetNowPlayingApplicationIsPlayingPointer, to: MRMediaRemoteGetNowPlayingApplicationIsPlayingFunction.self)
        print("✅ Got MRMediaRemoteGetNowPlayingApplicationIsPlaying function pointer")

        if let ApplicationIsPlaying = self.MRMediaRemoteGetNowPlayingApplicationIsPlaying {
            print("🔍 Checking if music is already playing...")
            ApplicationIsPlaying(DispatchQueue.main, { (isPlaying) in
                print("🎶 Initial playback state: \(isPlaying ? "PLAYING" : "NOT PLAYING")")
                self.isPlaying = isPlaying
            })
        }

        print("📡 Registering for notifications...")
        registerNotifications()
        print("🔄 Updating initial track info...")
        updateInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerNotifications() {
        print("📡 Registering for MediaRemote notifications...")
        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRNowPlayingPlaybackQueueChangedNotification"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"), object: nil)
        print("✅ Registered for queue change and playback state notifications")
        
        // not sure if these are required for some specific behaviour but doesn't look like that they change anything behaviour-wise
//        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRPlaybackQueueContentItemsChangedNotification"), object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRMediaRemoteNowPlayingApplicationClientStateDidChange"), object: nil)
    }

    func updateInfo() {
        print("🔄 Requesting now playing info from MediaRemote...")
        guard let MRMediaRemoteGetNowPlayingInfo = self.MRMediaRemoteGetNowPlayingInfo else {
            print("❌ MRMediaRemoteGetNowPlayingInfo not available")
            return
        }

        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
            if information.isEmpty {
                print("⚠️ MediaRemote returned empty response - likely permission denied")
                print("💡 Check System Settings > Privacy & Security > Media & Apple Music")
                print("💡 Ensure Rosco is enabled and try restarting the app")
            } else {
                print("📨 Received MediaRemote info response: \(information.count) items")
            }
            if information["kMRMediaRemoteNowPlayingInfoArtist"] == nil &&
                information["kMRMediaRemoteNowPlayingInfoTitle"] != nil {
                print("⚠️ Ignoring video content (probably YouTube from Safari)")
                return
            }
            
            var track: Track?
            if let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                if (artist.count == 0) {
                    print("⚠️ Empty artist name, ignoring track")
                    return
                }
                track = Track(name: title, artist: artist)
                print("🎵 Track info - Title: '\(title)' by '\(artist)'")
            } else {
                print("⚠️ No valid artist/title found in MediaRemote info")
            }
            
            if track != nil && self.isPlaying {
                print("▶️ Music playing - sending update notification")
                self.sendUpdateTrackNotification(track: track!)
            } else {
                print("⏹️ Music not playing - sending not playing notification (playing: \(self.isPlaying))")
                self.sendNotPlayingNotification()
            }
        })
    }

    func sendUpdateTrackNotification(track: Track) {
        if (lastTrack != track) {
            print("🔔 Sending track update notification: '\(track.name)' by '\(track.artist)'")
            lastTrack = track
            NotificationCenter.default.post(name: Notification.Name("RoscoUpdateTrack"), object: track)
        } else {
            print("⏩ Track unchanged, not sending notification")
        }
    }

    func sendNotPlayingNotification() {
        print("🔔 Sending not playing notification")
        lastTrack = nil
        NotificationCenter.default.post(name: Notification.Name("RoscoNotPlaying"), object: nil)
    }

    @objc func infoChanged(_ notification: Notification) {
        print("🔄 MediaRemote notification received: \(notification.name)")
        // https://github.com/dimitarnestorov/MusicBar/blob/master/macos/GlobalState.m
        if let state = notification.userInfo?["kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey"] as? Bool {
            print("🎶 Playback state changed: \(state ? "PLAYING" : "NOT PLAYING")")
            self.isPlaying = state
        } else {
            print("📥 Queue change notification")
        }
        updateInfo()
    }
}
