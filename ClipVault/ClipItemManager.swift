//
//  ClipItemManager.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import Foundation
import CoreData
import AppKit

class ClipItemManager {
    static let shared = ClipItemManager()

    private let containerName = "ClipVault"
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: containerName)

        container.loadPersistentStores { description, error in
            if let error = error {
                print("ClipItemManager: Error loading persistent store: \(error)")
                print("ClipItemManager: Store URL: \(description.url?.path ?? "unknown")")
                fatalError("Unable to load persistent stores: \(error)")
            }
            print("ClipItemManager: Successfully loaded persistent store at: \(description.url?.path ?? "unknown")")
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

        return container
    }()

    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    private let settings = SettingsManager.shared
    private let encryption = EncryptionManager.shared

    private init() {}

    // MARK: - Public Methods

    /// Saves a new clipboard item with encryption
    func saveClipItem(content: ClipContent, appBundleID: String?) throws -> ClipItem {
        // Compute hash for deduplication
        let hash = computeHash(for: content)

        // Check if item already exists
        if let existingItem = try? fetchItemByHash(hash) {
            // Update timestamp and return existing item
            existingItem.dateAdded = Date()
            try context.save()
            return existingItem
        }

        // Create new item
        let item = ClipItem(context: context)
        item.id = UUID()
        item.dateAdded = Date()
        item.isPinned = false
        item.contentHash = hash
        item.appBundleID = appBundleID

        // Encrypt and store content
        switch content {
        case .text(let string):
            try item.setEncryptedText(string)
        case .rtf(let plainText, let rtfData):
            // Store BOTH plain text (for search/preview) and RTF data (for pasting)
            try item.setEncryptedText(plainText)
            try item.setEncryptedRTF(rtfData)
        }

        try context.save()

        // Enforce max items limit
        try enforceMaxItemsLimit()

        return item
    }

    /// Fetches all clipboard items sorted by date (pinned first)
    func fetchAllItems() throws -> [ClipItem] {
        let request = ClipItem.fetchAllRequest()
        return try context.fetch(request)
    }

    /// Fetches items matching a search query
    func searchItems(query: String) throws -> [ClipItem] {
        let allItems = try fetchAllItems()

        // Filter items by decrypting and matching text content
        let lowercasedQuery = query.lowercased()
        return allItems.filter { item in
            if let text = item.getDecryptedText() {
                return text.lowercased().contains(lowercasedQuery)
            }
            return false
        }
    }

    /// Fetches the most recent item
    func fetchMostRecentItem() throws -> ClipItem? {
        let request = ClipItem.fetchAllRequest()
        request.fetchLimit = 1
        let items = try context.fetch(request)
        return items.first
    }

    /// Toggles the pinned status of an item
    func togglePin(item: ClipItem) throws {
        item.isPinned.toggle()
        try context.save()
    }

    /// Deletes a specific item
    func deleteItem(_ item: ClipItem) throws {
        context.delete(item)
        try context.save()
    }

    /// Clears all non-pinned items
    func clearHistory() throws {
        let request = ClipItem.fetchRequest()
        request.predicate = NSPredicate(format: "isPinned == NO")

        let items = try context.fetch(request)
        items.forEach { context.delete($0) }
        try context.save()
    }

    /// Clears ALL items (including pinned)
    func clearAll() throws {
        let request = ClipItem.fetchRequest()
        let items = try context.fetch(request)
        items.forEach { context.delete($0) }
        try context.save()
    }

    /// Writes an item to the system pasteboard
    func writeToPasteboard(_ item: ClipItem) -> Bool {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        // If RTF data exists, paste as RTF; otherwise paste as plain text
        if let rtfData = item.getDecryptedRTF() {
            return pasteboard.setData(rtfData, forType: .rtf)
        } else if let text = item.getDecryptedText() {
            return pasteboard.setString(text, forType: .string)
        }

        return false
    }

    // MARK: - Private Methods

    private func fetchItemByHash(_ hash: String) throws -> ClipItem? {
        let request = ClipItem.fetchByHashRequest(hash: hash)
        let items = try context.fetch(request)
        return items.first
    }

    private func enforceMaxItemsLimit() throws {
        let maxItems = settings.maxHistoryItems

        let request = ClipItem.fetchRequest()
        request.predicate = NSPredicate(format: "isPinned == NO")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ClipItem.dateAdded, ascending: false)]

        let unpinnedItems = try context.fetch(request)

        if unpinnedItems.count > maxItems {
            let itemsToDelete = unpinnedItems.suffix(from: maxItems)
            itemsToDelete.forEach { context.delete($0) }
            try context.save()
        }
    }

    private func computeHash(for content: ClipContent) -> String {
        switch content {
        case .text(let string):
            return ClipItem.computeHash(for: string)
        case .rtf(let plainText, _):
            // Use plain text for hash so same content with different formatting = duplicate
            return ClipItem.computeHash(for: plainText)
        }
    }
}

// MARK: - ClipContent Enum

enum ClipContent {
    case text(String)
    case rtf(plainText: String, rtfData: Data)
}
