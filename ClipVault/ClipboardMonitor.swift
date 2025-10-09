//
//  ClipboardMonitor.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import Foundation
import AppKit

class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isMonitoring = false

    private let settings = SettingsManager.shared
    private let itemManager = ClipItemManager.shared
    private let exclusionManager = ExclusionManager.shared

    // Callback invoked when a new clipboard item is detected and saved
    var onNewClipDetected: ((ClipItem) -> Void)?

    private init() {}

    deinit {
        stopMonitoring()
    }

    // MARK: - Public Methods

    /// Starts monitoring the clipboard for changes
    func startMonitoring(interval: TimeInterval = 0.3) {
        guard !isMonitoring else { return }

        // Initialize with current change count
        lastChangeCount = NSPasteboard.general.changeCount

        // Set up timer for polling
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.checkForClipboardChanges()
        }

        isMonitoring = true
        print("ClipboardMonitor: Started monitoring")
    }

    /// Stops monitoring the clipboard
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        isMonitoring = false
        print("ClipboardMonitor: Stopped monitoring")
    }

    // MARK: - Private Methods

    private func checkForClipboardChanges() {
        let currentChangeCount = NSPasteboard.general.changeCount

        // Check if pasteboard has changed
        guard currentChangeCount != lastChangeCount else { return }

        lastChangeCount = currentChangeCount

        // Capture the new clipboard content
        captureClipboard()
    }

    private func captureClipboard() {
        let pasteboard = NSPasteboard.general

        // Get the frontmost application bundle ID
        let frontmostApp = NSWorkspace.shared.frontmostApplication
        let appBundleID = frontmostApp?.bundleIdentifier

        // Check if this app should be excluded
        if let bundleID = appBundleID, exclusionManager.shouldExclude(appBundleID: bundleID) {
            print("ClipboardMonitor: Skipping capture from excluded app: \(bundleID)")
            return
        }

        // Try to capture different types based on settings and availability
        // PRIORITY ORDER: RTF > Plain Text
        // This ensures rich formatting (bold, italic, colors) is preserved when available

        // Priority 1: RTF (preserves formatting like bold, italic, colors)
        if settings.captureRTF, let rtfData = pasteboard.data(forType: .rtf), !rtfData.isEmpty {
            do {
                // Extract plain text from RTF for preview and search
                let plainText: String
                if let attributedString = NSAttributedString(rtf: rtfData, documentAttributes: nil) {
                    plainText = attributedString.string
                } else {
                    // Fallback: try to get plain text from pasteboard
                    plainText = pasteboard.string(forType: .string) ?? "[Rich Text]"
                }

                // Check if plain text content should be filtered
                if settings.contentFilterEnabled, exclusionManager.isLikelySensitive(content: plainText) {
                    print("ClipboardMonitor: Skipping likely sensitive RTF content")
                    return
                }

                let item = try itemManager.saveClipItem(
                    content: .rtf(plainText: plainText, rtfData: rtfData),
                    appBundleID: appBundleID
                )
                onNewClipDetected?(item)
                print("ClipboardMonitor: ✓ Captured RTF format (\(rtfData.count) bytes, \(plainText.count) chars)")
            } catch {
                print("ClipboardMonitor: Error saving RTF item: \(error)")
            }
        }
        // Priority 2: Plain text (only if RTF not available)
        else if settings.captureText, let string = pasteboard.string(forType: .string), !string.isEmpty {
            // Check if content should be filtered
            if settings.contentFilterEnabled, exclusionManager.isLikelySensitive(content: string) {
                print("ClipboardMonitor: Skipping likely sensitive content")
                return
            }

            do {
                let item = try itemManager.saveClipItem(
                    content: .text(string),
                    appBundleID: appBundleID
                )
                onNewClipDetected?(item)
                print("ClipboardMonitor: ✓ Captured plain text format (\(string.prefix(50))...)")
            } catch {
                print("ClipboardMonitor: Error saving text item: \(error)")
            }
        }
        else {
            print("ClipboardMonitor: No text content detected or text capture disabled")
        }
    }
}
