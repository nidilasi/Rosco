//
//  AppSettings.swift
//  Rosco
//
//  Created by Claude Code on 25/12/2024.
//

import Foundation

class AppSettings {
    static let shared = AppSettings()

    private let bundleIdentifiersKey = "RoscoBundleIdentifiers"
    private let filterModeKey = "RoscoFilterMode"

    enum FilterMode: String {
        case include // Whitelist mode
        case exclude // Blacklist mode
    }

    private init() {
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: bundleIdentifiersKey) == nil {
            bundleIdentifiers = []
        }

        if UserDefaults.standard.object(forKey: filterModeKey) == nil {
            filterMode = .exclude
        }
    }

    var bundleIdentifiers: [String] {
        get {
            return UserDefaults.standard.stringArray(forKey: bundleIdentifiersKey) ?? []
        }
        set {
            UserDefaults.standard.set(newValue, forKey: bundleIdentifiersKey)
        }
    }

    var filterMode: FilterMode {
        get {
            guard let rawValue = UserDefaults.standard.string(forKey: filterModeKey),
                  let mode = FilterMode(rawValue: rawValue) else {
                return .include
            }
            return mode
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: filterModeKey)
        }
    }

    func shouldAllowApp(bundleIdentifier: String) -> Bool {
        let contains = bundleIdentifiers.contains(bundleIdentifier)

        switch filterMode {
        case .include:
            return contains // Whitelist: only allow if in list
        case .exclude:
            return !contains // Blacklist: allow if NOT in list
        }
    }
}
