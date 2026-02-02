//
//  DemoDataFactory.swift
//  ClipVault
//
//  Created by Edd on 2026-02-02.
//

#if DEBUG
import AppKit
import CoreData
import Foundation

/// Factory for creating demo data for App Store screenshots.
enum DemoDataFactory {

    /// Populates the Core Data context with sample clipboard items.
    static func populateData(context: NSManagedObjectContext, for mode: DemoMode) {
        guard mode.hasData else { return }

        let items: [(text: String, appBundleID: String, isPinned: Bool, minutesAgo: Int, isRTF: Bool)]

        switch mode {
        case .pinnedItems:
            items = pinnedItemsData()
        case .withHistory, .historyWindow:
            items = standardHistoryData()
        case .empty, .historyWindowEmpty:
            return
        }

        for item in items {
            createClipItem(
                context: context,
                text: item.text,
                appBundleID: item.appBundleID,
                isPinned: item.isPinned,
                minutesAgo: item.minutesAgo,
                isRTF: item.isRTF
            )
        }

        try? context.save()
    }

    // MARK: - Sample Data Sets

    private static func standardHistoryData() -> [(text: String, appBundleID: String, isPinned: Bool, minutesAgo: Int, isRTF: Bool)] {
        [
            // Recent items
            (
                text: "func calculateTotal(_ items: [CartItem]) -> Double {\n    return items.reduce(0) { $0 + $1.price }\n}",
                appBundleID: "com.apple.dt.Xcode",
                isPinned: false,
                minutesAgo: 2,
                isRTF: false
            ),
            (
                text: "https://developer.apple.com/documentation/swiftui",
                appBundleID: "com.apple.Safari",
                isPinned: true,
                minutesAgo: 15,
                isRTF: false
            ),
            (
                text: "Meeting tomorrow at 10am to discuss the new feature roadmap. Please review the attached documents beforehand.",
                appBundleID: "com.apple.mail",
                isPinned: false,
                minutesAgo: 45,
                isRTF: true
            ),
            (
                text: "{\n  \"name\": \"ClipVault\",\n  \"version\": \"1.0.0\",\n  \"description\": \"Secure clipboard manager\"\n}",
                appBundleID: "com.microsoft.VSCode",
                isPinned: false,
                minutesAgo: 120,
                isRTF: false
            ),
            (
                text: "Remember to update the README with installation instructions and add screenshots for the App Store listing.",
                appBundleID: "com.apple.Notes",
                isPinned: true,
                minutesAgo: 180,
                isRTF: false
            ),
            (
                text: "git commit -m \"feat: add clipboard encryption with AES-256-GCM\"",
                appBundleID: "com.apple.Terminal",
                isPinned: false,
                minutesAgo: 240,
                isRTF: false
            ),
            (
                text: "The quick brown fox jumps over the lazy dog. This sentence contains every letter of the alphabet.",
                appBundleID: "com.apple.TextEdit",
                isPinned: false,
                minutesAgo: 360,
                isRTF: true
            ),
            (
                text: "support@example.com",
                appBundleID: "com.apple.Safari",
                isPinned: false,
                minutesAgo: 480,
                isRTF: false
            ),
        ]
    }

    private static func pinnedItemsData() -> [(text: String, appBundleID: String, isPinned: Bool, minutesAgo: Int, isRTF: Bool)] {
        [
            // Pinned items
            (
                text: "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJKpK...",
                appBundleID: "com.apple.Terminal",
                isPinned: true,
                minutesAgo: 5,
                isRTF: false
            ),
            (
                text: "https://api.example.com/v2/production",
                appBundleID: "com.apple.Safari",
                isPinned: true,
                minutesAgo: 30,
                isRTF: false
            ),
            (
                text: "Company Address:\n123 Tech Boulevard\nSan Francisco, CA 94105",
                appBundleID: "com.apple.Notes",
                isPinned: true,
                minutesAgo: 60,
                isRTF: false
            ),
            (
                text: "Standard response template for customer inquiries regarding subscription plans and pricing.",
                appBundleID: "com.apple.mail",
                isPinned: true,
                minutesAgo: 120,
                isRTF: true
            ),
            (
                text: "Project meeting link: https://meet.example.com/weekly-sync",
                appBundleID: "com.tinyspeck.slackmacgap",
                isPinned: true,
                minutesAgo: 180,
                isRTF: false
            ),
            // A few recent unpinned items
            (
                text: "Just copied this text for quick reference",
                appBundleID: "com.apple.TextEdit",
                isPinned: false,
                minutesAgo: 1,
                isRTF: false
            ),
            (
                text: "Another recent clipboard entry",
                appBundleID: "com.apple.Safari",
                isPinned: false,
                minutesAgo: 10,
                isRTF: false
            ),
        ]
    }

    // MARK: - Item Creation

    private static func createClipItem(
        context: NSManagedObjectContext,
        text: String,
        appBundleID: String,
        isPinned: Bool,
        minutesAgo: Int,
        isRTF: Bool
    ) {
        let item = ClipItem(context: context)
        item.id = UUID()
        item.dateAdded = Date().addingTimeInterval(TimeInterval(-minutesAgo * 60))
        item.isPinned = isPinned
        item.appBundleID = appBundleID
        item.contentHash = ClipItem.computeHash(for: text)

        // Encrypt the text content
        try? item.setEncryptedText(text)

        // For RTF items, create simple RTF data
        if isRTF {
            if let rtfData = createSimpleRTF(from: text) {
                try? item.setEncryptedRTF(rtfData)
            }
        }
    }

    private static func createSimpleRTF(from text: String) -> Data? {
        let attributedString = NSAttributedString(string: text)
        return try? attributedString.data(
            from: NSRange(location: 0, length: attributedString.length),
            documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]
        )
    }
}
#endif
