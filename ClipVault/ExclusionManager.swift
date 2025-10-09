//
//  ExclusionManager.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import Foundation
import AppKit

class ExclusionManager {
    static let shared = ExclusionManager()

    private let settings = SettingsManager.shared

    // Common apps that should be excluded by default (password managers, banking, etc.)
    private let defaultExcludedApps = [
        "com.agilebits.onepassword7",
        "com.agilebits.onepassword-osx",
        "com.lastpass.lastpassmacdesktop",
        "com.bitwarden.desktop",
        "org.keepassx.keepassxc",
        "com.apple.keychainaccess"
    ]

    private init() {}

    // MARK: - App-based Exclusions

    /// Checks if an app should be excluded from clipboard capture
    func shouldExclude(appBundleID: String) -> Bool {
        // Check user-configured exclusions
        if settings.excludedAppBundleIDs.contains(appBundleID) {
            return true
        }

        // Check default exclusions
        if defaultExcludedApps.contains(appBundleID) {
            return true
        }

        return false
    }

    // MARK: - Content-based Filtering

    /// Checks if content is likely sensitive and should be filtered
    func isLikelySensitive(content: String) -> Bool {
        // Skip if content filtering is disabled
        guard settings.contentFilterEnabled else { return false }

        // Check for various patterns that might indicate sensitive data

        // 1. JWT tokens (eyJ... pattern)
        if content.hasPrefix("eyJ") && content.count > 50 {
            return true
        }

        // 2. SSH private keys
        if content.contains("-----BEGIN") && (
            content.contains("PRIVATE KEY") ||
            content.contains("RSA PRIVATE KEY") ||
            content.contains("OPENSSH PRIVATE KEY")
        ) {
            return true
        }

        // 3. API keys or tokens (long alphanumeric strings)
        if isLongAlphanumeric(content) {
            return true
        }

        // 4. Credit card numbers (basic check for 13-19 digit sequences)
        if containsCreditCardPattern(content) {
            return true
        }

        // 5. Password-like patterns (common password field prefixes)
        let lowercased = content.lowercased()
        if (lowercased.hasPrefix("password:") ||
            lowercased.hasPrefix("pass:") ||
            lowercased.hasPrefix("pwd:") ||
            lowercased.hasPrefix("secret:")) && content.count < 100 {
            return true
        }

        return false
    }

    // MARK: - Private Helper Methods

    private func isLongAlphanumeric(_ string: String) -> Bool {
        // Check if string is a long continuous alphanumeric (likely a token/key)
        let alphanumeric = CharacterSet.alphanumerics

        // Remove whitespace and newlines
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        // If it's too short or too long, it's probably not a token
        guard trimmed.count >= 20 && trimmed.count <= 200 else {
            return false
        }

        // Check if it's mostly alphanumeric (allowing some special chars like - and _)
        let allowedChars = alphanumeric.union(CharacterSet(charactersIn: "-_"))
        let filtered = trimmed.unicodeScalars.filter { allowedChars.contains($0) }

        // If 90%+ is alphanumeric, it's likely a token
        let ratio = Double(filtered.count) / Double(trimmed.count)
        return ratio > 0.9
    }

    private func containsCreditCardPattern(_ string: String) -> Bool {
        // Remove spaces and dashes
        let digits = string.filter { $0.isNumber }

        // Credit cards are typically 13-19 digits
        guard digits.count >= 13 && digits.count <= 19 else {
            return false
        }

        // Basic Luhn algorithm check (simplified)
        // If the entire string is just digits (or digits with spaces/dashes), it might be a CC
        let cleaned = string.replacingOccurrences(of: " ", with: "")
                           .replacingOccurrences(of: "-", with: "")

        if cleaned.count == digits.count && digits.count >= 13 {
            return true
        }

        return false
    }

    // MARK: - Public Utility Methods

    /// Returns a list of common password manager bundle IDs
    func getCommonPasswordManagers() -> [String] {
        return defaultExcludedApps
    }

    /// Suggests exclusions for the current frontmost app
    func suggestExclusionForCurrentApp(completion: @escaping (String?, String?) -> Void) {
        if let app = NSWorkspace.shared.frontmostApplication,
           let bundleID = app.bundleIdentifier {
            let appName = app.localizedName ?? bundleID
            completion(bundleID, appName)
        } else {
            completion(nil, nil)
        }
    }
}
