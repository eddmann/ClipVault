//
//  AppLogger.swift
//  ClipVault
//
//  Centralized logging infrastructure using Apple's unified logging system (os.log/Logger).
//  Provides structured, privacy-aware logging with subsystems and categories.
//

import Foundation
import OSLog

/// Centralized logging infrastructure for ClipVault
/// Uses Apple's unified logging system for production-ready, structured logging
///
/// Benefits:
/// - Privacy-aware: Sensitive data automatically redacted
/// - Performance: Debug logs have near-zero cost when disabled
/// - Integration: Works with Console.app and `log` command
/// - Structured: Subsystems and categories for filtering
/// - Persistent: Logs stored by system, queryable later
///
/// Usage:
/// ```swift
/// AppLogger.clipboard.info("Started monitoring")
/// AppLogger.clipboard.debug("Captured item: \(itemId, privacy: .private)")
/// AppLogger.clipboard.error("Failed to save: \(error)")
/// ```
struct AppLogger {
    /// The app's subsystem identifier (reverse DNS)
    private static let subsystem = "com.clipvault"

    // MARK: - Category Loggers

    /// Logging for clipboard monitoring operations
    /// Use for: clipboard capture, changeCount polling, paste operations
    static let clipboard = Logger(subsystem: subsystem, category: "clipboard")

    /// Logging for encryption/decryption operations
    /// Use for: key generation, encrypt/decrypt, keychain operations
    static let encryption = Logger(subsystem: subsystem, category: "encryption")

    /// Logging for Core Data operations
    /// Use for: fetch, save, delete, migration
    static let persistence = Logger(subsystem: subsystem, category: "persistence")

    /// Logging for UI interactions and lifecycle
    /// Use for: menu actions, window lifecycle, user interactions
    static let ui = Logger(subsystem: subsystem, category: "ui")

    /// Logging for privacy/security features
    /// Use for: content filtering, app exclusions, sensitive data detection
    static let privacy = Logger(subsystem: subsystem, category: "privacy")

    /// Logging for settings and preferences
    /// Use for: UserDefaults changes, configuration updates
    static let settings = Logger(subsystem: subsystem, category: "settings")

    /// Logging for application lifecycle
    /// Use for: startup, shutdown, state transitions
    static let lifecycle = Logger(subsystem: subsystem, category: "lifecycle")
}

// MARK: - Privacy Helpers

extension AppLogger {
    /// Helper to log item IDs in a privacy-safe way
    /// Shows first 8 characters for correlation without exposing full UUID
    static func formatItemId(_ id: UUID?) -> String {
        guard let id = id else { return "unknown" }
        return String(id.uuidString.prefix(8))
    }

    /// Helper to log content metadata without exposing actual content
    static func formatContentMetadata(charCount: Int, byteCount: Int? = nil) -> String {
        if let bytes = byteCount {
            return "chars: \(charCount), bytes: \(bytes)"
        }
        return "chars: \(charCount)"
    }
}

// MARK: - Console.app Query Examples

/*
 To view logs in Console.app or terminal:

 1. All ClipVault logs:
    log show --predicate 'subsystem == "com.clipvault"' --last 1h

 2. Only clipboard operations:
    log show --predicate 'subsystem == "com.clipvault" AND category == "clipboard"' --last 1h

 3. Only errors:
    log show --predicate 'subsystem == "com.clipvault" AND messageType == error' --last 1h

 4. Real-time streaming:
    log stream --predicate 'subsystem == "com.clipvault"'

 5. Debug logs (requires enabling debug mode):
    sudo log config --mode "level:debug" --subsystem com.clipvault
    log stream --predicate 'subsystem == "com.clipvault"' --level debug
 */
