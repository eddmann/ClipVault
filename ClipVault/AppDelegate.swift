//
//  AppDelegate.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import AppKit
import SwiftUI
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var searchField: NSSearchField!
    private var currentSearchQuery: String = ""

    private let clipboardMonitor = ClipboardMonitor.shared
    private let itemManager = ClipItemManager.shared
    private let settings = SettingsManager.shared
    private let pasteHelper = PasteHelper.shared

    private var settingsWindow: NSWindow?
    private var viewAllWindow: NSWindow?
    private var previousFrontmostApp: NSRunningApplication?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "list.clipboard.fill", accessibilityDescription: "ClipVault")
            button.image?.isTemplate = true
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Set up clipboard monitor
        clipboardMonitor.onNewClipDetected = { item in
            let itemId = AppLogger.formatItemId(item.id)
            AppLogger.ui.debug("New clip detected (id: \(itemId, privacy: .public), pinned: \(item.isPinned))")
        }
        clipboardMonitor.startMonitoring()

        AppLogger.lifecycle.info("Application started successfully")
    }

    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor.stopMonitoring()
    }

    // MARK: - Menu Bar Actions

    @objc private func statusBarButtonClicked() {
        let event = NSApp.currentEvent!

        if event.type == .rightMouseUp {
            // Right click - show context menu with settings/quit
            showContextMenu()
        } else {
            // Left click - show main clipboard history menu
            showMenu()
        }
    }

    private func showMenu() {
        // Capture frontmost app BEFORE activating ClipVault (for auto-paste focus restoration)
        previousFrontmostApp = NSWorkspace.shared.frontmostApplication

        // Reset search when opening menu
        currentSearchQuery = ""

        buildMainMenu()
        statusItem.menu = menu

        statusItem.button?.performClick(nil)

        // Clear menu reference after showing (so button click works next time)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    private func showContextMenu() {
        let contextMenu = NSMenu()

        contextMenu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(NSMenuItem(title: "Quit ClipVault", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = contextMenu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { [weak self] in
            self?.statusItem.menu = nil
        }
    }

    private func buildMainMenu() {
        menu = NSMenu()

        // Search field - create once
        let searchItem = NSMenuItem()

        // Create container view for padding
        let containerView = NSView(frame: NSRect(x: 0, y: 0, width: 280, height: 36))
        searchField = NSSearchField(frame: NSRect(x: 12, y: 6, width: 256, height: 24))
        searchField.placeholderString = "Search clipboard..."

        // Configure visual properties for better visibility
        searchField.focusRingType = .default
        searchField.isBordered = true
        searchField.bezelStyle = .squareBezel
        searchField.drawsBackground = true
        
        searchField.refusesFirstResponder = true

        containerView.addSubview(searchField)

        // Use notification observer for real-time search
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(searchFieldTextDidChange(_:)),
            name: NSControl.textDidChangeNotification,
            object: searchField
        )

        searchItem.view = containerView
        menu.addItem(searchItem)

        menu.addItem(NSMenuItem.separator())

        // Add results
        addResultsToMenu()

        menu.addItem(NSMenuItem.separator())

        // Footer
        menu.addItem(NSMenuItem(title: "Clipboard History", action: #selector(openViewAll), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: ""))
    }

    private func addResultsToMenu(at insertIndex: Int? = nil) {
        var currentIndex = insertIndex ?? menu.numberOfItems

        // Fetch items
        do {
            let items: [ClipItem]
            if currentSearchQuery.isEmpty {
                items = try itemManager.fetchAllItems()
            } else {
                items = try itemManager.searchItems(query: currentSearchQuery)
            }

            // Separate pinned and regular items
            let pinnedItems = items.filter { $0.isPinned }
            let regularItems = items.filter { !$0.isPinned }

            // Show pinned section
            if !pinnedItems.isEmpty {
                let pinnedHeader = NSMenuItem(title: "📌 PINNED", action: nil, keyEquivalent: "")
                pinnedHeader.isEnabled = false
                menu.insertItem(pinnedHeader, at: currentIndex)
                currentIndex += 1

                for item in pinnedItems.prefix(10) {
                    menu.insertItem(createClipItemMenuItem(item), at: currentIndex)
                    currentIndex += 1
                }

                menu.insertItem(NSMenuItem.separator(), at: currentIndex)
                currentIndex += 1
            }

            // Show recent items
            if !regularItems.isEmpty {
                let recentHeader = NSMenuItem(title: "RECENT", action: nil, keyEquivalent: "")
                recentHeader.isEnabled = false
                menu.insertItem(recentHeader, at: currentIndex)
                currentIndex += 1

                for item in regularItems.prefix(20) {
                    menu.insertItem(createClipItemMenuItem(item), at: currentIndex)
                    currentIndex += 1
                }
            } else if pinnedItems.isEmpty {
                if !currentSearchQuery.isEmpty {
                    let noResultsItem = NSMenuItem(title: "No results found", action: nil, keyEquivalent: "")
                    noResultsItem.isEnabled = false
                    menu.insertItem(noResultsItem, at: currentIndex)
                } else {
                    let emptyItem = NSMenuItem(title: "No clipboard history", action: nil, keyEquivalent: "")
                    emptyItem.isEnabled = false
                    menu.insertItem(emptyItem, at: currentIndex)
                }
            }

        } catch {
            let errorItem = NSMenuItem(title: "Error loading history", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.insertItem(errorItem, at: currentIndex)
        }
    }

    private func createClipItemMenuItem(_ item: ClipItem) -> NSMenuItem {
        let preview = item.getPreviewText()
        let timeAgo = item.getRelativeTimeString()

        let menuItem = NSMenuItem(title: "\(preview) (\(timeAgo))", action: #selector(clipItemSelected(_:)), keyEquivalent: "")
        menuItem.representedObject = item

        // Set icon based on app bundle ID
        if let bundleID = item.appBundleID,
           let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            icon.size = NSSize(width: 16, height: 16)
            menuItem.image = icon
        }

        // Create context menu for right-click
        let contextMenu = NSMenu()
        contextMenu.addItem(withTitle: "Copy", action: #selector(copyItemToPasteboard(_:)), keyEquivalent: "").representedObject = item
        contextMenu.addItem(withTitle: "Paste", action: #selector(pasteItem(_:)), keyEquivalent: "").representedObject = item
        contextMenu.addItem(NSMenuItem.separator())

        let pinTitle = item.isPinned ? "Unpin" : "Pin"
        contextMenu.addItem(withTitle: pinTitle, action: #selector(togglePinItem(_:)), keyEquivalent: "").representedObject = item

        contextMenu.addItem(NSMenuItem.separator())
        contextMenu.addItem(withTitle: "Delete", action: #selector(deleteItem(_:)), keyEquivalent: "").representedObject = item

        menuItem.submenu = contextMenu

        return menuItem
    }

    // MARK: - Actions

    @objc private func searchFieldTextDidChange(_ notification: Notification) {
        currentSearchQuery = searchField.stringValue

        AppLogger.ui.debug("Search query changed (length: \(self.currentSearchQuery.count))")

        // Remove all items except search field (index 0), separator (index 1), final separator and footer
        // Count backwards to avoid index issues
        let itemCount = menu.numberOfItems

        // Keep: [0] = search field, [1] = separator, [last-3] = separator, [last-2] = View All, [last-1] = Settings
        // Remove everything in between (the results section)
        for i in stride(from: itemCount - 4, through: 2, by: -1) {
            menu.removeItem(at: i)
        }

        // Re-add results at position 2 (after search field and first separator)
        addResultsToMenu(at: 2)

        // Update the menu display
        menu.update()
    }

    @objc private func clipItemSelected(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem else { return }

        let autoPaste = settings.autoPasteOnSelect

        if autoPaste {
            // Auto-paste is enabled - check permissions
            if pasteHelper.checkAccessibilityPermissions() {
                // Have permissions - paste and show notification (restore focus to previous app)
                _ = pasteHelper.pasteItem(item, autoPaste: true, targetApp: previousFrontmostApp)
                NotificationManager.shared.showPastedNotification()
            } else {
                // No permissions - just prompt, don't copy
                pasteHelper.promptForAccessibilityPermissions()
            }
        } else {
            // Auto-paste disabled - just copy
            _ = pasteHelper.pasteItem(item, autoPaste: false)
            let itemId = AppLogger.formatItemId(item.id)
            AppLogger.ui.debug("Item copied (id: \(itemId, privacy: .public))")
            NotificationManager.shared.showCopiedNotification()
        }
    }

    @objc private func copyItemToPasteboard(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem else { return }
        _ = itemManager.writeToPasteboard(item)
        NotificationManager.shared.showCopiedNotification()
    }

    @objc private func pasteItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem else { return }

        // Check if we have accessibility permissions before attempting paste
        if pasteHelper.checkAccessibilityPermissions() {
            _ = pasteHelper.pasteItem(item, autoPaste: true, targetApp: previousFrontmostApp)
            NotificationManager.shared.showPastedNotification()
        } else {
            // No permissions - just prompt, don't copy
            pasteHelper.promptForAccessibilityPermissions()
        }
    }

    @objc private func togglePinItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem else { return }
        do {
            try itemManager.togglePin(item: item)
            let itemId = AppLogger.formatItemId(item.id)
            AppLogger.ui.debug("Toggled pin (id: \(itemId, privacy: .public), pinned: \(item.isPinned))")
        } catch {
            AppLogger.ui.error("Failed to toggle pin: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc private func deleteItem(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? ClipItem else { return }
        let itemId = AppLogger.formatItemId(item.id)
        do {
            try itemManager.deleteItem(item)
            AppLogger.ui.debug("Deleted item (id: \(itemId, privacy: .public))")
        } catch {
            AppLogger.ui.error("Failed to delete item: \(error.localizedDescription, privacy: .public)")
        }
    }

    @objc private func clearHistoryWithConfirmation() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will delete all non-pinned items from your clipboard history. Pinned items will be kept."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            do {
                try itemManager.clearHistory()
                AppLogger.ui.info("Cleared clipboard history")
            } catch {
                AppLogger.ui.error("Failed to clear history: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    @objc private func openSettings() {
        // If settings window already exists, bring it to front
        if let window = settingsWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create settings window
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "ClipVault Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 550, height: 500))
        window.center()
        window.makeKeyAndOrderFront(nil)

        settingsWindow = window

        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func openViewAll() {
        // If view all window already exists, bring it to front
        if let window = viewAllWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create view all window
        let historyView = ClipboardHistoryView()
        let hostingController = NSHostingController(rootView: historyView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Clipboard History"
        window.styleMask = [.titled, .closable, .resizable]
        window.setContentSize(NSSize(width: 900, height: 600))
        window.center()
        window.makeKeyAndOrderFront(nil)

        viewAllWindow = window

        NSApp.activate(ignoringOtherApps: true)
    }

    private func pasteLastItem() {
        do {
            if let item = try itemManager.fetchMostRecentItem() {
                _ = pasteHelper.pasteItem(item, autoPaste: true)
                let itemId = AppLogger.formatItemId(item.id)
                AppLogger.ui.debug("Pasted last item (id: \(itemId, privacy: .public))")
            }
        } catch {
            AppLogger.ui.error("Failed to paste last item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
