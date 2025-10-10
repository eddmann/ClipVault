//
//  SettingsView.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import OSLog

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsView(viewModel: viewModel)
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            PrivacySettingsView(viewModel: viewModel)
                .tabItem {
                    Label("Privacy", systemImage: "lock.shield")
                }

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(.top, 12)
        .frame(width: 550, height: 500)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @State private var showingClearConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Clipboard Capture Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Clipboard Capture")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 16) {
                        // Max History Items
                        HStack {
                            Text("Maximum History Items")
                                .font(.subheadline)

                            Spacer()

                            Picker("", selection: $viewModel.maxHistoryItems) {
                                Text("50").tag(50)
                                Text("100").tag(100)
                                Text("150").tag(150)
                                Text("200").tag(200)
                                Text("300").tag(300)
                                Text("400").tag(400)
                                Text("500").tag(500)
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                            .frame(width: 100)
                        }

                        Divider()

                        // Capture RTF
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Capture Rich Text Formatting")
                                    .font(.subheadline)
                                Text("Preserve bold, italic, colors, and other formatting")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.captureRTF)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Behavior Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Behavior")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Auto-paste on Select")
                                    .font(.subheadline)
                                Text("Automatically paste when clicking an item (requires Accessibility permission)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.autoPasteOnSelect)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }

                // History Management Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("History Management")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        Button(action: {
                            showingClearConfirmation = true
                        }) {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear All History")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.red)
                        .controlSize(.large)

                        Text("This will permanently delete all non-pinned items from your clipboard history.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }
            }
            .padding(20)
        }
        .alert("Clear Clipboard History?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("This will delete all non-pinned items from your clipboard history. Pinned items will be kept.")
        }
    }
}

// MARK: - Privacy Settings

struct PrivacySettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Content Filtering Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Content Filtering")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Filter Sensitive Content")
                                    .font(.subheadline)
                                Text("Automatically skip capturing content that looks like passwords, API keys, credit card numbers, or authentication tokens")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer()

                            Toggle("", isOn: $viewModel.contentFilterEnabled)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Excluded Apps Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Excluded Applications")
                        .font(.headline)
                        .foregroundColor(.primary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Don't capture clipboard content from these applications")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if viewModel.excludedAppBundleIDs.isEmpty {
                            HStack {
                                Spacer()
                                VStack(spacing: 8) {
                                    Image(systemName: "app.dashed")
                                        .font(.system(size: 32))
                                        .foregroundColor(.secondary.opacity(0.5))
                                    Text("No excluded apps")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 20)
                                Spacer()
                            }
                        } else {
                            VStack(spacing: 8) {
                                ForEach(viewModel.excludedAppBundleIDs, id: \.self) { bundleID in
                                    HStack(spacing: 12) {
                                        // App icon
                                        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                                            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Image(systemName: "app")
                                                .font(.system(size: 24))
                                                .foregroundColor(.secondary)
                                                .frame(width: 32, height: 32)
                                        }

                                        // App name
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(viewModel.getAppName(for: bundleID))
                                                .font(.subheadline)
                                            Text(bundleID)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }

                                        Spacer()

                                        // Remove button
                                        Button(action: {
                                            viewModel.removeExcludedApp(bundleID)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.secondary)
                                                .font(.system(size: 20))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Remove from excluded apps")
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(Color(nsColor: .windowBackgroundColor))
                                    .cornerRadius(6)
                                }
                            }
                        }

                        Button(action: {
                            viewModel.browseForApp()
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Browse for Application...")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                    .padding()
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Encryption Info Section
                HStack(spacing: 8) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    Text("All clipboard content is encrypted at rest using AES-256-GCM")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 40)

                // App Icon
                if let appIconImage = NSImage(named: "AppIcon") {
                    Image(nsImage: appIconImage)
                        .resizable()
                        .frame(width: 128, height: 128)
                        .cornerRadius(22)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                } else {
                    Image(systemName: "doc.on.clipboard.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.accentColor)
                }

                Spacer()
                    .frame(height: 24)

                // App Name
                Text("ClipVault")
                    .font(.system(size: 28, weight: .semibold))

                Spacer()
                    .frame(height: 8)

                // Version
                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()
                    .frame(height: 32)

                // Copyright
                VStack(spacing: 8) {
                    Text("© 2025 Edd Mann")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Secure clipboard manager for macOS")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
                    .frame(height: 32)

                // Project Link
                VStack(spacing: 12) {
                    Link(destination: URL(string: "https://github.com/eddmann/ClipVault")!) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                            Text("View Project on GitHub")
                        }
                        .frame(maxWidth: 280)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - View Model

class SettingsViewModel: ObservableObject {
    private let settings = SettingsManager.shared

    @Published var maxHistoryItems: Int {
        didSet { settings.maxHistoryItems = maxHistoryItems }
    }

    @Published var captureRTF: Bool {
        didSet { settings.captureRTF = captureRTF }
    }

    @Published var autoPasteOnSelect: Bool {
        didSet { settings.autoPasteOnSelect = autoPasteOnSelect }
    }

    @Published var contentFilterEnabled: Bool {
        didSet { settings.contentFilterEnabled = contentFilterEnabled }
    }

    @Published var excludedAppBundleIDs: [String] {
        didSet { settings.excludedAppBundleIDs = excludedAppBundleIDs }
    }

    init() {
        self.maxHistoryItems = settings.maxHistoryItems
        self.captureRTF = settings.captureRTF
        self.autoPasteOnSelect = settings.autoPasteOnSelect
        self.contentFilterEnabled = settings.contentFilterEnabled
        self.excludedAppBundleIDs = settings.excludedAppBundleIDs
    }

    func addExcludedApp(_ bundleID: String) {
        settings.addExcludedApp(bundleID: bundleID)
        excludedAppBundleIDs = settings.excludedAppBundleIDs
    }

    func removeExcludedApp(_ bundleID: String) {
        settings.removeExcludedApp(bundleID: bundleID)
        excludedAppBundleIDs = settings.excludedAppBundleIDs
    }

    func clearHistory() {
        do {
            try ClipItemManager.shared.clearHistory()
            AppLogger.ui.info("Cleared clipboard history from settings")
        } catch {
            AppLogger.ui.error("Failed to clear history: \(error.localizedDescription, privacy: .public)")
        }
    }

    func browseForApp() {
        let panel = NSOpenPanel()
        panel.message = "Select an application to exclude from clipboard monitoring"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }

            // Extract bundle identifier from the selected app
            if let bundle = Bundle(url: url),
               let bundleID = bundle.bundleIdentifier {
                self?.addExcludedApp(bundleID)
            }
        }
    }

    func getAppName(for bundleID: String) -> String {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID
        }

        // Try to get the localized app name from the bundle
        if let bundle = Bundle(url: appURL),
           let appName = bundle.localizedInfoDictionary?["CFBundleName"] as? String ?? bundle.infoDictionary?["CFBundleName"] as? String {
            return appName
        }

        // Fallback to the app's file name without extension
        return appURL.deletingPathExtension().lastPathComponent
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
