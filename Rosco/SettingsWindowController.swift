//
//  SettingsWindowController.swift
//  Rosco
//
//  Created by Claude Code on 25/12/2024.
//

import Cocoa
import SwiftUI
import UniformTypeIdentifiers

class SettingsWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 550),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Rosco Settings"
        window.center()

        let settingsView = SettingsView()
        let hostingView = NSHostingView(rootView: settingsView)
        window.contentView = hostingView

        self.init(window: window)
    }
}

struct SettingsView: View {
    @State private var bundleIdentifiers: [String]
    @State private var filterMode: AppSettings.FilterMode
    @State private var onClickAction: AppSettings.OnClickAction
    @State private var newBundleID: String = ""

    init() {
        let settings = AppSettings.shared
        _bundleIdentifiers = State(initialValue: settings.bundleIdentifiers)
        _filterMode = State(initialValue: settings.filterMode)
        _onClickAction = State(initialValue: settings.onClickAction)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Application Filter Settings")
                .font(.title2)
                .fontWeight(.semibold)

            // Filter Mode Picker
            VStack(alignment: .leading, spacing: 8) {
                Text("Filter Mode:")
                    .font(.headline)

                Picker("", selection: $filterMode) {
                    Text("Include Only (Whitelist)").tag(AppSettings.FilterMode.include)
                    Text("Exclude Only (Blacklist)").tag(AppSettings.FilterMode.exclude)
                }
                .pickerStyle(.radioGroup)
                .onChange(of: filterMode) { newValue in
                    AppSettings.shared.filterMode = newValue
                }

                Text(filterMode == .include ?
                     "Only applications in the list will be tracked" :
                     "All applications except those in the list will be tracked")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // Bundle Identifiers List
            VStack(alignment: .leading, spacing: 8) {
                Text("Bundle Identifiers:")
                    .font(.headline)

                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(bundleIdentifiers, id: \.self) { identifier in
                            HStack {
                                Text(identifier)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                Button(action: {
                                    removeBundleIdentifier(identifier)
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(height: 300)
                .border(Color.secondary.opacity(0.2))
            }

            // Add New Bundle Identifier
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    TextField("com.example.app", text: $newBundleID)
                        .textFieldStyle(.roundedBorder)

                    Button("Add") {
                        addBundleIdentifier()
                    }
                    .disabled(newBundleID.isEmpty)
                }

                Button("Select App...") {
                    selectAppFromApplications()
                }

                Text("Tip: Use 'Select App' to automatically add apps, or enter bundle identifiers manually.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Divider()

            // On Click Action
            VStack(alignment: .leading, spacing: 8) {
                Text("On Click:")
                    .font(.headline)

                Picker("", selection: $onClickAction) {
                    Text("Do nothing").tag(AppSettings.OnClickAction.doNothing)
                    Text("Focus Application that plays the current track").tag(AppSettings.OnClickAction.focusTrackSource)
                }
                .pickerStyle(.radioGroup)
                .onChange(of: onClickAction) { newValue in
                    AppSettings.shared.onClickAction = newValue
                }

                Text("Action to perform when clicking Rosco")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 500, height: 550)
    }

    private func addBundleIdentifier() {
        let trimmed = newBundleID.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !bundleIdentifiers.contains(trimmed) else {
            return
        }

        bundleIdentifiers.append(trimmed)
        AppSettings.shared.bundleIdentifiers = bundleIdentifiers
        newBundleID = ""
    }

    private func removeBundleIdentifier(_ identifier: String) {
        bundleIdentifiers.removeAll { $0 == identifier }
        AppSettings.shared.bundleIdentifiers = bundleIdentifiers
    }

    private func selectAppFromApplications() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.message = "Select applications to add to the filter list"

        panel.begin { response in
            guard response == .OK else { return }

            for url in panel.urls {
                if let bundle = Bundle(url: url),
                   let bundleID = bundle.bundleIdentifier {
                    // Add if not already in the list
                    if !bundleIdentifiers.contains(bundleID) {
                        bundleIdentifiers.append(bundleID)
                    }
                }
            }

            // Save to settings
            AppSettings.shared.bundleIdentifiers = bundleIdentifiers
        }
    }
}
