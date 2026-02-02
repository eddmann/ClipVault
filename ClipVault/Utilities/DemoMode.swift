//
//  DemoMode.swift
//  ClipVault
//
//  Created by Edd on 2026-02-02.
//

#if DEBUG
import Foundation

/// Demo modes for App Store screenshots.
/// Launch with `--demo <mode>` to activate.
enum DemoMode: String, CaseIterable {
    /// Empty clipboard history, shows "No clipboard history"
    case empty

    /// Populated with 8-10 sample items from various apps
    case withHistory

    /// Several pinned items to showcase pin feature
    case pinnedItems

    /// Shows the "Clipboard History" window with items
    case historyWindow

    /// Shows the "Clipboard History" window empty
    case historyWindowEmpty

    /// Parses demo mode from command line arguments.
    /// Returns nil if no valid demo mode is specified.
    static func fromArguments() -> DemoMode? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--demo"),
              index + 1 < args.count else { return nil }
        return DemoMode(rawValue: args[index + 1])
    }

    /// Whether this mode shows the history window
    var showsHistoryWindow: Bool {
        switch self {
        case .historyWindow, .historyWindowEmpty:
            return true
        default:
            return false
        }
    }

    /// Whether this mode should have populated data
    var hasData: Bool {
        switch self {
        case .empty, .historyWindowEmpty:
            return false
        case .withHistory, .pinnedItems, .historyWindow:
            return true
        }
    }
}
#endif
