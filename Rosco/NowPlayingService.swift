//
//  NowPlayingService.swift
//  Rosco
//
//  Created by Evan Robertson on 19/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//
import Cocoa

class NowPlayingService {
    typealias MRMediaRemoteRegisterForNowPlayingNotificationsFunction = @convention(c) (DispatchQueue) -> Void
    typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void

    var MRMediaRemoteGetNowPlayingInfo : MRMediaRemoteGetNowPlayingInfoFunction?
    var lastTrack: Track?
    var isPlaying: Bool = false
    
    init () {
        // Load framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        guard let MRMediaRemoteRegisterForNowPlayingNotificationsPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteRegisterForNowPlayingNotifications" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteGetNowPlayingInfo")
        }

        let MRMediaRemoteRegisterForNowPlayingNotifications = unsafeBitCast(MRMediaRemoteRegisterForNowPlayingNotificationsPointer, to: MRMediaRemoteRegisterForNowPlayingNotificationsFunction.self)
        MRMediaRemoteRegisterForNowPlayingNotifications(DispatchQueue.main);

        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else {
            fatalError("Failed to get function pointer: MRMediaRemoteGetNowPlayingInfo")
        }
        MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)

        registerNotifications()
        updateInfo()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func registerNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRNowPlayingPlaybackQueueChangedNotification"), object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(infoChanged(_:)), name: Notification.Name("kMRMediaRemoteNowPlayingApplicationIsPlayingDidChangeNotification"), object: nil)
    }

    func updateInfo() {
        guard let MRMediaRemoteGetNowPlayingInfo = self.MRMediaRemoteGetNowPlayingInfo else {
            return
        }

        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
            if (self.isPlaying) {
                if let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as? String,
                    let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as? String {
                    self.sendUpdateTrackNotification(track: Track(name: title, artist: artist))
                } else {
                    self.sendNotPlayingNotification()
                }
            } else {
                self.sendNotPlayingNotification()
            }
        })
    }

    func sendUpdateTrackNotification(track: Track) {
        if (lastTrack != track) {
            lastTrack = track
            NotificationCenter.default.post(name: Notification.Name("RoscoUpdateTrack"), object: track)
        }
    }

    func sendNotPlayingNotification() {
        lastTrack = nil
        NotificationCenter.default.post(name: Notification.Name("RoscoNotPlaying"), object: nil)
    }

    @objc func infoChanged(_ notification: Notification) {
        // https://github.com/dimitarnestorov/MusicBar/blob/master/macos/GlobalState.m
        if let state = notification.userInfo?["kMRMediaRemoteNowPlayingApplicationIsPlayingUserInfoKey"] as? Bool {
            self.isPlaying = state
        }
        updateInfo()
    }
}
