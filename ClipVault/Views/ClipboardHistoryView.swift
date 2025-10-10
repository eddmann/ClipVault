//
//  ClipboardHistoryView.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import SwiftUI
import Combine
import OSLog

struct ClipboardHistoryView: View {
    @StateObject private var viewModel = ClipboardHistoryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack(spacing: 12) {
                // Search field
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search clipboard...", text: $viewModel.searchQuery)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(6)
                .frame(width: 250)

                // App filter
                Picker("Filter by app:", selection: $viewModel.selectedAppFilter) {
                    Text("All Apps").tag(nil as String?)
                    Divider()
                    ForEach(viewModel.availableApps, id: \.self) { appBundleID in
                        Text(viewModel.getAppName(for: appBundleID)).tag(appBundleID as String?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 250)

                Spacer()

                // Refresh button
                Button(action: {
                    viewModel.refresh()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                .help("Refresh")

                // Results count
                Text("\(viewModel.filteredItems.count) items")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
            .padding()
            .background(Color(nsColor: .windowBackgroundColor))

            Divider()

            // Table
            Table(viewModel.filteredItems) {
                TableColumn("Preview") { item in
                    HStack(spacing: 4) {
                        // Show RTF indicator icon if item has rich text data
                        if item.rtfData != nil {
                            Image(systemName: "textformat")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                                .frame(width: 16, height: 16)
                                .help("Rich Text Format")
                        }

                        Text(item.getPreviewText(maxLength: 80))
                            .lineLimit(1)
                    }
                }
                .width(min: 200, ideal: 350, max: .infinity)

                TableColumn("Time") { item in
                    Text(item.getRelativeTimeString())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .width(ideal: 100)

                TableColumn("App") { item in
                    if let bundleID = item.appBundleID {
                        HStack(spacing: 6) {
                            // App icon
                            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
                                let icon = NSWorkspace.shared.icon(forFile: appURL.path)
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }

                            // App name
                            Text(viewModel.getAppName(for: bundleID))
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "questionmark.app")
                                .frame(width: 16, height: 16)
                                .foregroundColor(.secondary)
                            Text("Unknown")
                                .font(.caption)
                                .foregroundColor(.secondary.opacity(0.6))
                        }
                    }
                }
                .width(ideal: 150)

                TableColumn("Actions") { item in
                    HStack(spacing: 8) {
                        // Pin/Unpin
                        Button(action: {
                            viewModel.togglePin(item: item)
                        }) {
                            Image(systemName: item.isPinned ? "pin.fill" : "pin")
                                .foregroundColor(item.isPinned ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)
                        .help(item.isPinned ? "Unpin" : "Pin")

                        // Copy
                        Button(action: {
                            viewModel.copyToClipboard(item: item)
                        }) {
                            Image(systemName: "doc.on.doc")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                        .help("Copy")

                        // Delete
                        Button(action: {
                            viewModel.deleteItem(item: item)
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Delete")
                    }
                }
                .width(ideal: 100)
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .onAppear {
            viewModel.refresh()
        }
    }
}

// MARK: - ViewModel

class ClipboardHistoryViewModel: ObservableObject {
    @Published var items: [ClipItem] = []
    @Published var searchQuery: String = ""
    @Published var selectedAppFilter: String? = nil

    private let itemManager = ClipItemManager.shared

    var filteredItems: [ClipItem] {
        var result = items

        // Filter by search query
        if !searchQuery.isEmpty {
            result = result.filter { item in
                if let text = item.getDecryptedText() {
                    return text.lowercased().contains(searchQuery.lowercased())
                }
                return false
            }
        }

        // Filter by app
        if let appFilter = selectedAppFilter {
            result = result.filter { $0.appBundleID == appFilter }
        }

        return result
    }

    var availableApps: [String] {
        let apps = Set(items.compactMap { $0.appBundleID })
        return apps.sorted()
    }

    func refresh() {
        do {
            items = try itemManager.fetchAllItems()
            AppLogger.ui.debug("Refreshed items (count: \(self.items.count))")
        } catch {
            AppLogger.ui.error("Failed to fetch items: \(error.localizedDescription, privacy: .public)")
            items = []
        }
    }

    func togglePin(item: ClipItem) {
        do {
            try itemManager.togglePin(item: item)
            refresh()
            let itemId = AppLogger.formatItemId(item.id)
            AppLogger.ui.debug("Toggled pin (id: \(itemId, privacy: .public))")
        } catch {
            AppLogger.ui.error("Failed to toggle pin: \(error.localizedDescription, privacy: .public)")
        }
    }

    func copyToClipboard(item: ClipItem) {
        _ = itemManager.writeToPasteboard(item)
        NotificationManager.shared.showCopiedNotification()
        let itemId = AppLogger.formatItemId(item.id)
        AppLogger.ui.debug("Copied to clipboard (id: \(itemId, privacy: .public))")
    }

    func deleteItem(item: ClipItem) {
        let itemId = AppLogger.formatItemId(item.id)
        do {
            try itemManager.deleteItem(item)
            refresh()
            AppLogger.ui.debug("Deleted item (id: \(itemId, privacy: .public))")
        } catch {
            AppLogger.ui.error("Failed to delete item: \(error.localizedDescription, privacy: .public)")
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

struct ClipboardHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        ClipboardHistoryView()
    }
}
