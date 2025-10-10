//
//  PasteHelper.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import Foundation
import AppKit
import CoreGraphics
import OSLog

class PasteHelper {
    static let shared = PasteHelper()

    private init() {}

    // MARK: - Public Methods

    /// Pastes the given item by writing it to the pasteboard and optionally simulating ⌘V
    func pasteItem(_ item: ClipItem, autoPaste: Bool = false) -> Bool {
        // Write item to pasteboard
        let success = ClipItemManager.shared.writeToPasteboard(item)

        guard success else {
            AppLogger.clipboard.error("Failed to write item to pasteboard")
            return false
        }

        let itemId = AppLogger.formatItemId(item.id)
        AppLogger.clipboard.debug("Wrote to pasteboard (id: \(itemId, privacy: .public), autoPaste: \(autoPaste))")

        // If auto-paste is enabled, synthesize ⌘V
        if autoPaste {
            // Small delay to ensure pasteboard is updated
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.synthesizeCommandV()
            }
        }

        return true
    }

    /// Synthesizes Command+V keypress using CGEvent
    func synthesizeCommandV() {
        // Check if we have accessibility permissions
        guard checkAccessibilityPermissions() else {
            AppLogger.clipboard.error("Accessibility permissions required for auto-paste")
            return
        }

        // Create Command+V key events
        let vKeyCode: CGKeyCode = 9 // V key

        // Key down with Command modifier
        if let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: true) {
            keyDownEvent.flags = .maskCommand
            keyDownEvent.post(tap: .cghidEventTap)
        }

        // Key up
        if let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: vKeyCode, keyDown: false) {
            keyUpEvent.flags = .maskCommand
            keyUpEvent.post(tap: .cghidEventTap)
        }

        AppLogger.clipboard.debug("Synthesized ⌘V keypress")
    }

    /// Checks if the app has accessibility permissions
    func checkAccessibilityPermissions() -> Bool {
        return AXIsProcessTrusted()
    }

    /// Shows an alert prompting the user to grant accessibility permissions
    func promptForAccessibilityPermissions() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Permission Required"
        alert.informativeText = "ClipVault needs Accessibility permission to auto-paste clipboard items.\n\nPlease:\n1. Open System Settings\n2. Go to Privacy & Security → Accessibility\n3. Enable ClipVault\n4. Try pasting again"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // Open System Settings to Accessibility pane
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
    }

    // MARK: - Utility Methods

    /// Writes text directly to the pasteboard without pasting
    func copyTextToPasteboard(_ text: String) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setString(text, forType: .string)
    }

    /// Writes data to the pasteboard with a specific type
    func copyDataToPasteboard(_ data: Data, type: NSPasteboard.PasteboardType) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        return pasteboard.setData(data, forType: type)
    }
}
