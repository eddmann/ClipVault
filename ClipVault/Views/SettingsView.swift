//
//  SettingsView.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import SwiftUI
import UniformTypeIdentifiers
import OSLog

struct SettingsView: View {
    @State private var maxHistoryItems: Int = SettingsManager.shared.maxHistoryItems
    @State private var captureRTF: Bool = SettingsManager.shared.captureRTF
    @State private var autoPasteOnSelect: Bool = SettingsManager.shared.autoPasteOnSelect
    @State private var launchAtLogin: Bool = LaunchAtLoginManager.shared.isEnabled
    @State private var contentFilterEnabled: Bool = SettingsManager.shared.contentFilterEnabled
    @State private var excludedAppBundleIDs: [String] = SettingsManager.shared.excludedAppBundleIDs

    @State private var hasAccessibilityPermission = false
    @State private var permissionCheckTask: Task<Void, Never>?
    @State private var showingClearConfirmation = false

    var body: some View {
        contentView
            .onAppear {
                loadSettings()
                checkPermissionStatus()
                startPermissionCheckTimer()
            }
            .onDisappear {
                permissionCheckTask?.cancel()
                permissionCheckTask = nil
            }
    }

    private var contentView: some View {
        mainTabView
            .modifier(SettingsSyncModifier(
                maxHistoryItems: $maxHistoryItems,
                captureRTF: $captureRTF,
                autoPasteOnSelect: $autoPasteOnSelect,
                contentFilterEnabled: $contentFilterEnabled,
                excludedAppBundleIDs: $excludedAppBundleIDs
            ))
    }

    private var mainTabView: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gear") }
            privacyTab
                .tabItem { Label("Privacy", systemImage: "lock.shield") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 500)
    }

    // MARK: - General Tab

    private var generalTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            historyLimitSection
            captureRTFSection
            autoPasteSection
            launchAtLoginSection
            clearHistorySection
        }
        .padding(24)
    }

    private var historyLimitSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("History Limit")
                    .font(.subheadline)
                Text("Maximum number of items to keep")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("", selection: $maxHistoryItems) {
                Text("50").tag(50)
                Text("100").tag(100)
                Text("200").tag(200)
                Text("300").tag(300)
                Text("500").tag(500)
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .frame(width: 80)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var captureRTFSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Capture Rich Text")
                    .font(.subheadline)
                Text("Preserve bold, italic, colors, and other formatting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $captureRTF)
                .labelsHidden()
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var autoPasteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Auto-paste on Select", isOn: $autoPasteOnSelect)
                    .font(.subheadline)
                    .disabled(!hasAccessibilityPermission)

                Spacer()

                if !hasAccessibilityPermission {
                    Button(action: {
                        PasteHelper.shared.promptForAccessibilityPermissions()
                    }) {
                        Label("Grant Access", systemImage: "lock.shield")
                    }
                    .controlSize(.small)
                }
            }

            Text("Automatically paste when clicking an item")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var launchAtLoginSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Start at Login")
                    .font(.subheadline)
                Text("Automatically launch ClipVault when you log in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("", isOn: $launchAtLogin)
                .labelsHidden()
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .onChange(of: launchAtLogin) { _, newValue in
            if newValue != LaunchAtLoginManager.shared.isEnabled {
                LaunchAtLoginManager.shared.toggle()
                launchAtLogin = LaunchAtLoginManager.shared.isEnabled
            }
        }
    }

    private var clearHistorySection: some View {
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
            .controlSize(.regular)

            Text("Permanently delete all non-pinned items")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .alert("Clear Clipboard History?", isPresented: $showingClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear", role: .destructive) {
                clearHistory()
            }
        } message: {
            Text("This will delete all non-pinned items. Pinned items will be kept.")
        }
    }

    // MARK: - Privacy Tab

    private var privacyTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            contentFilterSection
            excludedAppsSection
            encryptionInfoSection
        }
        .padding(24)
    }

    private var contentFilterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Toggle("Filter Sensitive Content", isOn: $contentFilterEnabled)
                    .font(.subheadline)
            }

            Text("Skip capturing passwords, API keys, credit cards, and tokens")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var excludedAppsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Excluded Applications")
                .font(.subheadline)

            Text("Don't capture clipboard content from these apps")
                .font(.caption)
                .foregroundStyle(.secondary)

            if excludedAppBundleIDs.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 24))
                            .foregroundStyle(.secondary.opacity(0.5))
                        Text("No excluded apps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 12)
                    Spacer()
                }
            } else {
                VStack(spacing: 6) {
                    ForEach(excludedAppBundleIDs, id: \.self) { bundleID in
                        excludedAppRow(bundleID: bundleID)
                    }
                }
            }

            Button(action: { browseForApp() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Application")
                }
            }
            .controlSize(.small)
        }
        .padding()
        .background(.quaternary.opacity(0.3))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func excludedAppRow(bundleID: String) -> some View {
        HStack(spacing: 10) {
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: appURL.path))
                    .resizable()
                    .frame(width: 24, height: 24)
            } else {
                Image(systemName: "app")
                    .font(.system(size: 18))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
            }

            Text(getAppName(for: bundleID))
                .font(.subheadline)

            Spacer()

            Button(action: { removeExcludedApp(bundleID) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.borderless)
            .help("Remove from excluded apps")
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private var encryptionInfoSection: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(.green)
            Text("All content encrypted at rest using AES-256-GCM")
                .font(.caption)
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    // MARK: - About Tab

    private var aboutTab: some View {
        VStack(spacing: 24) {
            if let appIconImage = NSImage(named: "AppIcon") {
                Image(nsImage: appIconImage)
                    .resizable()
                    .frame(width: 128, height: 128)
                    .cornerRadius(22)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            } else {
                Image(systemName: "list.clipboard.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)
            }

            VStack(spacing: 8) {
                Text("ClipVault")
                    .font(.system(size: 28, weight: .semibold))

                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                    Text("Version \(version) (\(build))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            VStack(spacing: 4) {
                Text("© 2025 Edd Mann")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("Secure clipboard manager for macOS")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

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
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helper Methods

    private func loadSettings() {
        maxHistoryItems = SettingsManager.shared.maxHistoryItems
        captureRTF = SettingsManager.shared.captureRTF
        autoPasteOnSelect = SettingsManager.shared.autoPasteOnSelect
        launchAtLogin = LaunchAtLoginManager.shared.isEnabled
        contentFilterEnabled = SettingsManager.shared.contentFilterEnabled
        excludedAppBundleIDs = SettingsManager.shared.excludedAppBundleIDs
        checkPermissionStatus()
    }

    private func checkPermissionStatus() {
        hasAccessibilityPermission = PasteHelper.shared.checkAccessibilityPermissions()
    }

    private func startPermissionCheckTimer() {
        permissionCheckTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(2))
                guard !Task.isCancelled else { break }
                checkPermissionStatus()
            }
        }
    }

    private func clearHistory() {
        do {
            try ClipItemManager.shared.clearHistory()
            AppLogger.ui.info("Cleared clipboard history from settings")
        } catch {
            AppLogger.ui.error("Failed to clear history: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func browseForApp() {
        let panel = NSOpenPanel()
        panel.message = "Select an application to exclude"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.application]
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if let bundle = Bundle(url: url),
               let bundleID = bundle.bundleIdentifier {
                SettingsManager.shared.addExcludedApp(bundleID: bundleID)
                excludedAppBundleIDs = SettingsManager.shared.excludedAppBundleIDs
            }
        }
    }

    private func removeExcludedApp(_ bundleID: String) {
        SettingsManager.shared.removeExcludedApp(bundleID: bundleID)
        excludedAppBundleIDs = SettingsManager.shared.excludedAppBundleIDs
    }

    private func getAppName(for bundleID: String) -> String {
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
            return bundleID
        }
        if let bundle = Bundle(url: appURL),
           let appName = bundle.localizedInfoDictionary?["CFBundleName"] as? String ??
                         bundle.infoDictionary?["CFBundleName"] as? String {
            return appName
        }
        return appURL.deletingPathExtension().lastPathComponent
    }
}

// MARK: - Settings Sync ViewModifier

struct SettingsSyncModifier: ViewModifier {
    @Binding var maxHistoryItems: Int
    @Binding var captureRTF: Bool
    @Binding var autoPasteOnSelect: Bool
    @Binding var contentFilterEnabled: Bool
    @Binding var excludedAppBundleIDs: [String]

    func body(content: Content) -> some View {
        content
            .onChange(of: maxHistoryItems) { _, new in
                SettingsManager.shared.maxHistoryItems = new
            }
            .onChange(of: captureRTF) { _, new in
                SettingsManager.shared.captureRTF = new
            }
            .onChange(of: autoPasteOnSelect) { _, new in
                SettingsManager.shared.autoPasteOnSelect = new
            }
            .onChange(of: contentFilterEnabled) { _, new in
                SettingsManager.shared.contentFilterEnabled = new
            }
            .onChange(of: excludedAppBundleIDs) { _, new in
                SettingsManager.shared.excludedAppBundleIDs = new
            }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
