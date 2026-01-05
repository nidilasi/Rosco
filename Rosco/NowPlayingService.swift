//
//  NowPlayingService.swift
//  Rosco
//
//  Created by Evan Robertson on 19/04/2015.
//  Copyright (c) 2015 Evan Robertson. All rights reserved.
//

import Cocoa

class NowPlayingService {
    var lastTrack: Track?
    var isPlaying: Bool = false
    private var mediaControlProcess: Process?
    private var outputPipe: Pipe?

    init() {
        startMediaControlStream()
    }

    deinit {
        stopMediaControlStream()
    }

    private func startMediaControlStream() {
        mediaControlProcess = Process()
        outputPipe = Pipe()

        guard let process = mediaControlProcess, let pipe = outputPipe else {
            print("Failed to create process or pipe")
            return
        }

        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/media-control")
        process.arguments = ["stream", "--no-diff"]
        process.standardOutput = pipe
        process.standardError = pipe
        var buffer = Data()

        // Handle output asynchronously
        pipe.fileHandleForReading.readabilityHandler = { [weak self] fileHandle in
            let data = fileHandle.availableData
            guard !data.isEmpty else { return }
            
            buffer.append(data)

            while let range = buffer.firstRange(of: Data([0x0A])) { // '\n'
                let lineData = buffer.subdata(in: buffer.startIndex..<range.lowerBound)
                buffer.removeSubrange(buffer.startIndex...range.lowerBound)

                if let line = String(data: lineData, encoding: .utf8) {
                    guard !line.isEmpty else { continue }
                    self?.parseMediaControlOutput(line)
                }
            }
        }

        do {
            try process.run()
            print("media-control stream started successfully")
        } catch {
            print("Failed to start media-control: \(error)")
        }
    }

    private func stopMediaControlStream() {
        mediaControlProcess?.terminate()
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        mediaControlProcess = nil
        outputPipe = nil
    }
    
    private func isMusicPlayerApp(bundleIdentifier: String) -> Bool {
//        print("bundleIdentifier: \(bundleIdentifier)")
        return AppSettings.shared.shouldAllowApp(bundleIdentifier: bundleIdentifier)
    }

    private func parseMediaControlOutput(_ jsonString: String) {
        // Skip empty lines or lines that don't start with '{'
        let trimmed = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.hasPrefix("{") else { return }

        guard let data = trimmed.data(using: .utf8) else { return }

        do {
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload = json["payload"] as? [String: Any],
                  !payload.isEmpty else {
                return
            }

            // Extract playback information from payload
            let bundleIdentifier = payload["bundleIdentifier"] as? String ?? "none"
//            let mediaType = payload["mediaType"] as? String ?? "no mediaType"
            let title = payload["title"] as? String
            let artist = payload["artist"] as? String
            let playing = payload["playing"] as? Bool ?? false
            
            // Update playing state
            let wasPlaying = self.isPlaying
            
            // filtering possible by "bundleIdentifer" & "mediaType"
            // we cannot just skip these states, otherwise Rosco would never update when
            // ... switching from a Music app to a Safari/Youtube video for example while
            // ... keeping the Music app running. the Music app needs to be re-activated by
            // ... pausing/unpausing before we get ANY event from it again
            // this is due to media-control limitations and how the nowplaying control works
            self.isPlaying = playing && isMusicPlayerApp(bundleIdentifier: bundleIdentifier)

            // Filter out content without artist (e.g., YouTube videos from Safari)
            guard let artistString = artist, !artistString.isEmpty else {
                if wasPlaying {
                    self.sendNotPlayingNotification()
                }
                return
            }

            // Create track if we have both title and artist
            if let titleString = title, !titleString.isEmpty {
                let track = Track(name: titleString, artist: artistString)

                if self.isPlaying {
                    self.sendUpdateTrackNotification(track: track, trackSourceBundleId: bundleIdentifier)
                } else {
                    self.sendNotPlayingNotification()
                }
            } else {
                if wasPlaying {
                    self.sendNotPlayingNotification()
                }
            }

        } catch let error {
            print(error.localizedDescription)
        }
    }

    func sendUpdateTrackNotification(track: Track, trackSourceBundleId: String) {
        if (lastTrack != track) {
            lastTrack = track
            NotificationCenter.default.post(name: Notification.Name("RoscoUpdateTrack"), object: track, userInfo: ["trackSourceBundleId": trackSourceBundleId])
        }
    }

    func sendNotPlayingNotification() {
        lastTrack = nil
        NotificationCenter.default.post(name: Notification.Name("RoscoNotPlaying"), object: nil)
    }
}
