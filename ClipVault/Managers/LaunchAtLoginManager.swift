//
//  LaunchAtLoginManager.swift
//  ClipVault
//
//  Created by Edd on 21/10/2025.
//

import AppKit
import Foundation
import ServiceManagement

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    var isEnabled: Bool {
        get {
            if #available(macOS 13.0, *) {
                return SMAppService.mainApp.status == .enabled
            } else {
                // For older macOS versions, fall back to UserDefaults
                return SettingsManager.shared.launchAtLogin
            }
        }
    }

    func enable() throws {
        if #available(macOS 13.0, *) {
            try SMAppService.mainApp.register()
        } else {
            // For older macOS, we can't programmatically set this
            // Users would need to add manually via System Preferences
            SettingsManager.shared.launchAtLogin = true
            showLegacyInstructions()
        }
    }

    func disable() throws {
        if #available(macOS 13.0, *) {
            try SMAppService.mainApp.unregister()
        } else {
            SettingsManager.shared.launchAtLogin = false
        }
    }

    func toggle() {
        do {
            if isEnabled {
                try disable()
            } else {
                try enable()
            }
            SettingsManager.shared.launchAtLogin = isEnabled
        } catch {
            print("Error toggling launch at login: \(error)")
            showError(error)
        }
    }

    private func showLegacyInstructions() {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Launch at Login"
            alert.informativeText = "To enable launch at login on your macOS version, please:\n\n1. Open System Preferences\n2. Go to Users & Groups\n3. Click Login Items\n4. Add ClipVault to the list"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }

    private func showError(_ error: Error) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Launch at Login Error"
            alert.informativeText = "Failed to update launch at login settings:\n\(error.localizedDescription)"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
