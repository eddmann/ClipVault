# ClipVault - Implementation Guide

**Version:** 1.2
**Last Updated:** October 10, 2025
**Swift Version:** 5.9+
**Minimum macOS:** 12.0 (Monterey)

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Technology Stack](#technology-stack)
3. [Project Structure](#project-structure)
4. [Core Components](#core-components)
5. [Data Layer](#data-layer)
6. [Security Implementation](#security-implementation)
7. [User Interface](#user-interface)
8. [Notification System](#notification-system)
9. [Key Algorithms & Flows](#key-algorithms--flows)
10. [Configuration & Setup](#configuration--setup)
11. [Testing Strategy](#testing-strategy)
12. [Known Issues & Limitations](#known-issues--limitations)
13. [Future Work](#future-work)

---

## Architecture Overview

ClipVault follows a **layered architecture** pattern with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  (AppDelegate, SettingsView, NSMenu, NSStatusItem,         │
│   ClipboardHistoryView, NotificationManager)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                       │
│  (ClipboardMonitor, ExclusionManager, PasteHelper)         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  (ClipItemManager, Core Data Stack)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                        │
│  (EncryptionManager, SettingsManager, Keychain)            │
└─────────────────────────────────────────────────────────────┘
```

### Design Patterns Used

- **Singleton Pattern**: All manager classes (shared instances)
- **Observer Pattern**: Callbacks for clipboard events, notification observers
- **Strategy Pattern**: Content filtering via ExclusionManager
- **Repository Pattern**: ClipItemManager abstracts Core Data access
- **MVVM Pattern**: SettingsView and ClipboardHistoryView use ViewModel for state management

---

## Technology Stack

### Frameworks & Libraries

- **AppKit**: Native macOS UI framework for menu bar interface and panels
- **SwiftUI**: Modern UI framework for settings window and notifications
- **Core Data**: Persistent storage with object-relational mapping
- **CryptoKit**: Apple's cryptography framework (AES-GCM, SHA-256)
- **Security**: Keychain Services for key storage
- **CoreGraphics**: Low-level event synthesis for auto-paste
- **Combine**: Reactive programming for settings binding
- **OSLog**: Apple's unified logging system for structured, privacy-aware logging

### Development Tools

- **Xcode**: 15.0+ (required for Swift 5.9 features)
- **Swift**: 5.9+ (leverages latest language features)
- **Git**: Version control

---

## Project Structure

```
ClipVault/
├── ClipVault.xcodeproj          # Xcode project file
├── ClipVault/
│   ├── ClipVaultApp.swift       # SwiftUI app entry point (@main)
│   ├── AppDelegate.swift        # AppKit app delegate (menu bar UI)
│   ├── Info.plist              # App metadata (LSUIElement: true)
│   ├── ClipVault.entitlements  # App sandbox entitlements
│   │
│   ├── Models/
│   │   └── ClipItem+Extensions.swift  # Core Data model + extensions
│   │
│   ├── Views/
│   │   ├── SettingsView.swift         # SwiftUI settings interface
│   │   ├── ClipboardHistoryView.swift # View All window
│   │   └── CopyNotificationView.swift # Visual notification UI
│   │
│   ├── Managers/
│   │   ├── ClipItemManager.swift      # Core Data operations
│   │   ├── ClipboardMonitor.swift     # Clipboard polling
│   │   ├── EncryptionManager.swift    # AES-GCM encryption
│   │   ├── SettingsManager.swift      # UserDefaults wrapper
│   │   ├── ExclusionManager.swift     # Content/app filtering
│   │   ├── PasteHelper.swift          # Auto-paste functionality
│   │   ├── NotificationManager.swift  # Visual notification system
│   │   └── AppLogger.swift            # Centralized logging infrastructure
│   │
│   └── ClipVault.xcdatamodeld/
│       └── ClipVault.xcdatamodel/
│           └── contents               # Core Data model XML
│
├── PRODUCT_REQUIREMENTS.md     # Product specification (PRD)
├── IMPLEMENTATION_GUIDE.md     # This file
└── README.md                   # (Future) User-facing documentation
```

---

## Core Components

### 1. AppDelegate.swift

**Purpose**: Main application controller for menu bar interface

**Location**: `ClipVault/AppDelegate.swift` (398 lines)

**Key Responsibilities:**

- Creates and manages NSStatusItem (menu bar icon)
- Builds dynamic NSMenu with clipboard history
- Handles search field for real-time filtering
- Displays source app icons for each clipboard item
- Coordinates user actions (click, right-click)
- Opens settings and View All windows
- Triggers visual notifications via NotificationManager

**Important Methods:**

```swift
class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var searchField: NSSearchField!
    private var currentSearchQuery: String = ""
    private var settingsWindow: NSWindow?
    private var viewAllWindow: NSWindow?

    // Entry point - setup status bar and monitors
    func applicationDidFinishLaunching(_ notification: Notification)

    // Show main clipboard menu (left click)
    private func showMenu()

    // Show settings/quit context menu (right click)
    private func showContextMenu()

    // Build menu structure with search field + results
    private func buildMainMenu()

    // Add clipboard items to menu (called during search too)
    private func addResultsToMenu(at insertIndex: Int? = nil)

    // Create individual menu item for a ClipItem
    private func createClipItemMenuItem(_ item: ClipItem) -> NSMenuItem

    // Handle search field text changes (NotificationCenter)
    @objc private func searchFieldTextDidChange(_ notification: Notification)

    // User clicked a clipboard item
    @objc private func clipItemSelected(_ sender: NSMenuItem)

    // Copy item to clipboard
    @objc private func copyItemToPasteboard(_ sender: NSMenuItem)

    // Paste item with auto-paste
    @objc private func pasteItem(_ sender: NSMenuItem)
}
```

**Menu Bar Icon:**

```swift
button.image = NSImage(systemSymbolName: "list.clipboard.fill",
                       accessibilityDescription: "ClipVault")
```

**Search Implementation:**

- Uses `NotificationCenter.default.addObserver` for `NSControl.textDidChangeNotification`
- Updates menu in real-time by removing/rebuilding results section
- Preserves search field text during updates
- Maintains focus on search field during typing

**Notification Integration:**

```swift
// Show "Copied!" notification when copying
NotificationManager.shared.showCopiedNotification()

// Show "Pasted!" notification when pasting
NotificationManager.shared.showPastedNotification()
```

**Reference**: Line 25-43 (applicationDidFinishLaunching), Line 63-85 (showMenu), Line 101-141 (buildMainMenu), Line 239-259 (searchFieldTextDidChange), Line 261-282 (clipItemSelected)

---

### 2. ClipboardMonitor.swift

**Purpose**: Continuously monitors system clipboard for changes

**Location**: `ClipVault/ClipboardMonitor.swift` (140 lines)

**Architecture:**

- Uses **polling** approach (checks NSPasteboard.general.changeCount every 300ms)
- Singleton pattern (`ClipboardMonitor.shared`)
- Callback-based notification when new clip detected

**Key Methods:**

```swift
class ClipboardMonitor {
    static let shared = ClipboardMonitor()

    var onNewClipDetected: ((ClipItem) -> Void)?

    // Start polling clipboard
    func startMonitoring(interval: TimeInterval = 0.3)

    // Stop polling
    func stopMonitoring()

    // Check if changeCount has incremented
    private func checkForClipboardChanges()

    // Capture content from pasteboard
    private func captureClipboard()
}
```

**Capture Flow:**

1. Detect changeCount increment
2. **Get frontmost application bundle ID** (for source tracking)
3. Check exclusion rules (app + content filtering)
4. Try to read content in **priority order: RTF → Plain Text**
5. Save via ClipItemManager (with encryption, deduplication, and app bundle ID)
6. Invoke callback if successful

**Priority Order (IMPORTANT):**

```swift
// Priority 1: RTF (preserves formatting like bold, italic, colors)
if settings.captureRTF, let rtfData = pasteboard.data(forType: .rtf), !rtfData.isEmpty {
    // Extract plain text from RTF for preview and search
    // Store BOTH plain text (for search) and RTF data (for pasting)
    // ...
}
// Priority 2: Plain text (only if RTF not available)
else if settings.captureText, let string = pasteboard.string(forType: .string), !string.isEmpty {
    // ...
}
```

**Source App Tracking:**

```swift
// Get frontmost application
let frontmostApp = NSWorkspace.shared.frontmostApplication
let appBundleID = frontmostApp?.bundleIdentifier

// Pass to saveClipItem for storage
```

This enables:

- App icon display in menu and View All window
- Filtering by source application
- App-based exclusions
- Usage analytics per application

**Reference**: Line 34-47 (startMonitoring), Line 59-69 (checkForClipboardChanges), Line 71-138 (captureClipboard)

---

### 3. ClipItemManager.swift

**Purpose**: Repository for all Core Data operations on clipboard items

**Location**: `ClipVault/ClipItemManager.swift` (198 lines)

**Responsibilities:**

- Core Data stack initialization
- CRUD operations on ClipItem entities
- Encryption/decryption coordination
- Deduplication via content hashing
- Search functionality (decrypt in memory)
- Pasteboard integration

**Key Methods:**

```swift
class ClipItemManager {
    static let shared = ClipItemManager()

    private lazy var persistentContainer: NSPersistentContainer

    // Save new clip with encryption and deduplication
    func saveClipItem(content: ClipContent, appBundleID: String?) throws -> ClipItem

    // Fetch all items (pinned first, then by date)
    func fetchAllItems() throws -> [ClipItem]

    // Search items (decrypts in memory for matching)
    func searchItems(query: String) throws -> [ClipItem]

    // Most recent item (for potential "Paste Last" hotkey)
    func fetchMostRecentItem() throws -> ClipItem?

    // Toggle pin status
    func togglePin(item: ClipItem) throws

    // Delete single item
    func deleteItem(_ item: ClipItem) throws

    // Clear non-pinned items
    func clearHistory() throws

    // Clear ALL items (including pinned)
    func clearAll() throws

    // Write item back to system pasteboard
    func writeToPasteboard(_ item: ClipItem) -> Bool

    // Enforce max items limit (delete oldest unpinned)
    private func enforceMaxItemsLimit() throws

    // Compute hash for deduplication
    private func computeHash(for content: ClipContent) -> String
}
```

**ClipContent Enum:**

```swift
enum ClipContent {
    case text(String)
    case rtf(plainText: String, rtfData: Data)
}
```

**Deduplication Strategy:**

- Compute SHA-256 hash of content before saving
- For RTF content, hash is based on plain text (so same content with different formatting = duplicate)
- Check if hash exists in database
- If exists: update timestamp, return existing item
- If new: create new item with unique hash

**Storage Location:**
Uses Core Data's default persistent store location within the app's sandbox container.

**Reference**: Line 46-82 (saveClipItem), Line 91-102 (searchItems), Line 181-189 (computeHash)

---

### 4. NotificationManager.swift

**Purpose**: Manages visual on-screen notifications for copy/paste feedback

**Location**: `ClipVault/NotificationManager.swift` (150 lines)

**Architecture:**

- Singleton pattern (`NotificationManager.shared`)
- Uses NSPanel for overlay display
- SwiftUI-based notification view
- Auto-dismiss with timer

**Key Methods:**

```swift
class NotificationManager {
    static let shared = NotificationManager()

    private var notificationPanel: NSPanel?
    private var hideTimer: Timer?
    private var hostingController: NSHostingController<NotificationWrapper>?
    private var notificationState: NotificationState?

    // Shows the "Copied!" notification
    func showCopiedNotification()

    // Shows the "Pasted!" notification
    func showPastedNotification()

    // Generic notification display
    private func showNotification(message: String)

    // Create the notification panel
    private func createNotificationPanel()

    // Reset auto-hide timer
    private func resetHideTimer()

    // Hide notification with animation
    private func hideNotification()
}
```

**NotificationState (ObservableObject):**

```swift
class NotificationState: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var message: String = "Copied!"

    func show()
    func hide()
}
```

**Display Flow:**

1. Called from AppDelegate when copy/paste action occurs
2. Creates NSPanel if doesn't exist (or reuses existing)
3. Positions panel in center of main screen
4. Shows notification with spring animation
5. Sets timer to hide after 1.5 seconds
6. Fades out with animation

**Panel Configuration:**

```swift
let panel = NSPanel(
    contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
    styleMask: [.nonactivatingPanel, .borderless],
    backing: .buffered,
    defer: false
)

panel.isOpaque = false
panel.backgroundColor = .clear
panel.level = .statusBar  // Above most windows
panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
panel.ignoresMouseEvents = true  // Click-through
panel.hasShadow = false
```

**Reference**: Line 23-30 (showCopiedNotification/showPastedNotification), Line 32-71 (showNotification), Line 73-102 (createNotificationPanel), Line 104-123 (hideNotification)

---

### 5. CopyNotificationView.swift

**Purpose**: SwiftUI view for visual notification overlay

**Location**: `ClipVault/Views/CopyNotificationView.swift` (47 lines)

**Design:**

- Checkmark icon + message text
- Semi-transparent dark background
- Spring animation for appearance
- Scale and opacity effects

**Implementation:**

```swift
struct CopyNotificationView: View {
    @Binding var isVisible: Bool
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white)

            Text(message)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
        .opacity(isVisible ? 1 : 0)
        .scaleEffect(isVisible ? 1 : 0.8)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isVisible)
    }
}
```

**Visual Characteristics:**

- **Size**: Dynamic based on content
- **Background**: Black with 85% opacity
- **Border**: White with 20% opacity
- **Shadow**: Soft shadow for depth
- **Animation**: Spring with 0.3s response, 0.7 damping fraction

**Reference**: Full implementation in CopyNotificationView.swift

---

### 6. EncryptionManager.swift

**Purpose**: Handles all encryption/decryption operations

**Location**: `ClipVault/EncryptionManager.swift` (148 lines)

**Security Design:**

- Uses **AES-256-GCM** (authenticated encryption)
- Symmetric key generated once and stored in Keychain
- Key never leaves device (not synced)
- Key accessible only when device unlocked

**Key Methods:**

```swift
class EncryptionManager {
    static let shared = EncryptionManager()

    private let keyTag = "com.clipvault.encryption.key"
    private var cachedKey: SymmetricKey?

    // Encrypt raw data
    func encrypt(_ data: Data) throws -> Data

    // Decrypt data
    func decrypt(_ data: Data) throws -> Data

    // Convenience for string encryption
    func encryptString(_ string: String) throws -> Data
    func decryptString(_ data: Data) throws -> String

    // Retrieve or generate encryption key
    private func getOrCreateKey() throws -> SymmetricKey

    // Store key in Keychain
    private func saveKeyToKeychain(_ key: SymmetricKey) throws

    // Load key from Keychain
    private func loadKeyFromKeychain() throws -> Data
}
```

**Keychain Configuration:**

```swift
let query: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "com.clipvault.encryption.key",
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
    kSecValueData as String: keyData
]
```

**AES-GCM Flow:**

```swift
// Encryption
let key = try getOrCreateKey()
let sealedBox = try AES.GCM.seal(data, using: key)
return sealedBox.combined // Includes nonce + ciphertext + tag

// Decryption
let sealedBox = try AES.GCM.SealedBox(combined: data)
return try AES.GCM.open(sealedBox, using: key)
```

**Error Handling:**

```swift
enum EncryptionError: Error, LocalizedError {
    case encryptionFailed
    case decryptionFailed
    case invalidInput
    case invalidOutput
    case keyNotFound
    case keychainError(OSStatus)
}
```

**Reference**: Line 23-58 (encrypt/decrypt methods), Line 63-81 (getOrCreateKey), Line 83-118 (Keychain operations), Line 122-147 (EncryptionError)

---

### 7. ExclusionManager.swift

**Purpose**: Determines if clipboard content should be captured

**Location**: `ClipVault/ExclusionManager.swift` (152 lines)

**Two-Layer Filtering:**

1. **App-Based**: Exclude entire applications
2. **Content-Based**: Heuristic pattern matching

**Key Methods:**

```swift
class ExclusionManager {
    static let shared = ExclusionManager()

    // Check if app should be excluded
    func shouldExclude(appBundleID: String) -> Bool

    // Check if content looks sensitive
    func isLikelySensitive(content: String) -> Bool

    // Detect long alphanumeric tokens
    private func isLongAlphanumeric(_ string: String) -> Bool

    // Detect credit card patterns
    private func containsCreditCardPattern(_ string: String) -> Bool

    // Get list of common password managers
    func getCommonPasswordManagers() -> [String]
}
```

**Default Excluded Apps:**

```swift
private let defaultExcludedApps = [
    "com.agilebits.onepassword7",
    "com.agilebits.onepassword-osx",
    "com.lastpass.lastpassmacdesktop",
    "com.bitwarden.desktop",
    "org.keepassx.keepassxc",
    "com.apple.keychainaccess"
]
```

**Content Detection Patterns:**

1. **JWT Tokens**: Starts with "eyJ", length > 50
2. **SSH Keys**: Contains "-----BEGIN" + "PRIVATE KEY"
3. **API Keys**: Long alphanumeric (20-200 chars, >90% alphanum)
4. **Credit Cards**: 13-19 digits with basic Luhn check
5. **Passwords**: Prefixes like "password:", "pwd:", "secret:"

**Reference**: Line 31-43 (shouldExclude), Line 48-88 (isLikelySensitive), Line 92-132 (helper methods)

---

### 8. PasteHelper.swift

**Purpose**: Auto-paste functionality via event synthesis

**Location**: `ClipVault/PasteHelper.swift` (105 lines)

**Mechanism:**

- Writes item to NSPasteboard
- Synthesizes ⌘V keypress using CGEvent API
- Requires Accessibility permissions

**Key Methods:**

```swift
class PasteHelper {
    static let shared = PasteHelper()

    // Write to pasteboard + optionally auto-paste
    func pasteItem(_ item: ClipItem, autoPaste: Bool = false) -> Bool

    // Synthesize Command+V keypress
    func synthesizeCommandV()

    // Check if Accessibility permissions granted
    func checkAccessibilityPermissions() -> Bool

    // Prompt user to grant permissions
    func promptForAccessibilityPermissions()
}
```

**CGEvent Synthesis:**

```swift
let vKeyCode: CGKeyCode = 9 // V key

// Key down with Command modifier
let keyDownEvent = CGEvent(keyboardEventSource: nil,
                           virtualKey: vKeyCode,
                           keyDown: true)
keyDownEvent?.flags = .maskCommand
keyDownEvent?.post(tap: .cghidEventTap)

// Key up
let keyUpEvent = CGEvent(keyboardEventSource: nil,
                         virtualKey: vKeyCode,
                         keyDown: false)
keyUpEvent?.flags = .maskCommand
keyUpEvent?.post(tap: .cghidEventTap)
```

**Timing:**

```swift
// 50ms delay ensures pasteboard is updated before paste
DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
    self.synthesizeCommandV()
}
```

**Reference**: Line 20-38 (pasteItem), Line 41-64 (synthesizeCommandV), Line 72-87 (promptForAccessibilityPermissions)

---

### 9. SettingsManager.swift

**Purpose**: UserDefaults wrapper for all app preferences

**Location**: `ClipVault/SettingsManager.swift` (101 lines)

**Settings Categories:**

**General:**

- `maxHistoryItems: Int` (50-500 with preset options, default: 100)
- `captureText: Bool` (default: true) - **Internal flag**, not exposed in UI
- `captureRTF: Bool` (default: true) - Exposed in UI as "Capture Rich Text Formatting"
- `autoPasteOnSelect: Bool` (default: false)

**Privacy:**

- `contentFilterEnabled: Bool` (default: true)
- `excludedAppBundleIDs: [String]` (default: [])

**Helper Methods:**

```swift
func addExcludedApp(bundleID: String)
func removeExcludedApp(bundleID: String)
func resetToDefaults()
```

**Note**: `captureText` exists in code but is always `true` and not exposed in the settings UI. The UI only shows "Capture Rich Text Formatting" toggle for `captureRTF`.

**Reference**: Line 44-62 (general settings), Line 66-88 (privacy settings + helpers), Line 92-100 (resetToDefaults)

---

### 10. AppLogger.swift

**Purpose**: Centralized logging infrastructure using Apple's unified logging system

**Location**: `ClipVault/Managers/AppLogger.swift` (~150 lines)

**Key Features:**

- **Structured logging** with subsystems and categories
- **Privacy-aware** - automatic redaction of sensitive data
- **Performance optimized** - debug logs have near-zero cost when disabled
- **System integration** - works with Console.app and `log` command
- **Persistent** - logs stored by macOS, queryable later

**Log Categories:**

```swift
struct AppLogger {
    static let clipboard    // Clipboard monitoring, capture, paste operations
    static let encryption   // Encryption/decryption, key management, keychain
    static let persistence  // Core Data fetch, save, delete, migration
    static let ui           // Menu actions, window lifecycle, user interactions
    static let privacy      // Content filtering, app exclusions, sensitive data
    static let settings     // UserDefaults changes, configuration updates
    static let lifecycle    // App startup, shutdown, state transitions
}
```

**Usage Examples:**

```swift
// Lifecycle events (always logged)
AppLogger.lifecycle.info("Application started successfully")

// Debug information (only in debug mode)
AppLogger.clipboard.debug("Captured text (chars: \(count), app: \(bundleID, privacy: .public))")

// Errors (always logged)
AppLogger.persistence.error("Failed to save item: \(error.localizedDescription, privacy: .public)")
```

**Privacy Helpers:**

```swift
// Format item IDs safely (first 8 chars only)
let itemId = AppLogger.formatItemId(item.id)
AppLogger.ui.debug("Deleted item (id: \(itemId, privacy: .public))")

// Format content metadata without exposing actual content
let metadata = AppLogger.formatContentMetadata(charCount: 150, byteCount: 200)
AppLogger.clipboard.debug("Captured RTF: \(metadata, privacy: .public)")
```

**Viewing Logs:**

```bash
# Real-time streaming
log stream --predicate 'subsystem == "com.clipvault"'

# Last hour of clipboard operations
log show --predicate 'subsystem == "com.clipvault" AND category == "clipboard"' --last 1h

# Only errors
log show --predicate 'subsystem == "com.clipvault" AND messageType == error' --last 24h
```

**Key Benefits:**

- No sensitive clipboard content logged (only metadata)
- Automatic timestamps, process info, thread info
- Can be viewed in Console.app or via terminal
- Debug logs automatically disabled in release builds
- Structured queries for debugging specific issues

---

### 11. SettingsView.swift

**Purpose**: SwiftUI-based settings interface

**Location**: `ClipVault/Views/SettingsView.swift` (485 lines)

**Architecture:**

- TabView with 3 tabs: General, Privacy, About
- MVVM pattern with SettingsViewModel
- Two-way binding with @Published properties
- Modern card-based UI design

**Tabs:**

**1. General Tab (Line 39-169):**

- **Clipboard Capture Section:**
  - Maximum History Items: Dropdown picker (50-500)
  - Capture Rich Text Formatting: Toggle (captureRTF)
- **Behavior Section:**
  - Auto-paste on Select: Toggle (autoPasteOnSelect)
- **History Management Section:**
  - Clear All History button (confirmation dialog)

**2. Privacy Tab (Line 173-315):**

- **Content Filtering Section:**
  - Filter Sensitive Content: Toggle
  - Description of what it filters
- **Excluded Applications Section:**
  - Browse button (opens NSOpenPanel for /Applications)
  - List of excluded apps with:
    - App icon (32x32)
    - App name and bundle ID
    - Remove button
  - Empty state with icon when no exclusions
- **Encryption Status:**
  - Green badge with shield icon
  - "All clipboard content is encrypted at rest using AES-256-GCM"

**3. About Tab (Line 319-391):**

- App icon (128x128, rounded corners, shadow)
- App name "ClipVault" (28pt semibold)
- Version and build number from Bundle
- Copyright "© 2025 Edd Mann"
- Description "Secure clipboard manager for macOS"
- GitHub link button (https://github.com/eddmann/ClipVault)

**ViewModel Pattern (Line 395-478):**

```swift
class SettingsViewModel: ObservableObject {
    @Published var maxHistoryItems: Int {
        didSet { settings.maxHistoryItems = maxHistoryItems }
    }
    @Published var captureRTF: Bool {
        didSet { settings.captureRTF = captureRTF }
    }
    @Published var autoPasteOnSelect: Bool {
        didSet { settings.autoPasteOnSelect = autoPasteOnSelect }
    }
    @Published var contentFilterEnabled: Bool {
        didSet { settings.contentFilterEnabled = contentFilterEnabled }
    }
    @Published var excludedAppBundleIDs: [String] {
        didSet { settings.excludedAppBundleIDs = excludedAppBundleIDs }
    }

    // App browsing functionality
    func browseForApp()
    func getAppName(for bundleID: String) -> String
    func clearHistory()
}
```

**Window Configuration:**

- Size: 550x500 (fixed)
- 12px padding below title bar
- ScrollView for each tab
- No scroll bars appear (content fits)

**Reference**: Line 16-34 (TabView), Line 39-169 (GeneralSettingsView), Line 173-315 (PrivacySettingsView), Line 319-391 (AboutSettingsView), Line 395-478 (SettingsViewModel)

---

### 12. ClipboardHistoryView.swift

**Purpose**: Full-screen view for browsing and managing clipboard history

**Location**: `ClipVault/Views/ClipboardHistoryView.swift` (247 lines)

**Architecture:**

- SwiftUI Table view with sortable columns
- Real-time search filtering
- App-based filtering via dropdown
- MVVM pattern with ClipboardHistoryViewModel

**Key Features:**

**1. Source App Filtering:**

```swift
@Published var selectedAppFilter: String? = nil

var availableApps: [String] {
    let apps = Set(items.compactMap { $0.appBundleID })
    return apps.sorted()
}

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
```

**2. Toolbar Controls:**

- Search field (250px width)
- App filter dropdown (250px width)
  - "All Apps" option
  - Divider
  - List of all apps with clipboard items
- Refresh button
- Results count display

**3. Table Columns:**

- **Preview**: Text preview with RTF indicator icon (textformat SF Symbol)
- **Time**: Relative time string (e.g., "2m ago")
- **App**: Source app icon (16x16) and name
- **Actions**: Pin, Copy, Delete buttons

**App Icon Display:**

```swift
if let bundleID = item.appBundleID {
    HStack(spacing: 6) {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            let icon = NSWorkspace.shared.icon(forFile: appURL.path)
            Image(nsImage: icon)
                .resizable()
                .frame(width: 16, height: 16)
        }

        Text(viewModel.getAppName(for: bundleID))
            .font(.caption)
    }
} else {
    // Show "Unknown" for items without app bundle ID
    HStack(spacing: 6) {
        Image(systemName: "questionmark.app")
            .frame(width: 16, height: 16)
            .foregroundColor(.secondary)
        Text("Unknown")
            .font(.caption)
            .foregroundColor(.secondary.opacity(0.6))
    }
}
```

**Window Configuration:**

- Size: 900x600 (resizable)
- Minimum size: 800x500
- Opens via "View All..." menu item

**Notification Integration:**
When copying item from View All window, shows visual "Copied!" notification:

```swift
func copyToClipboard(item: ClipItem) {
    _ = itemManager.writeToPasteboard(item)
    NotificationManager.shared.showCopiedNotification()
}
```

**Reference**: Line 11-157 (ClipboardHistoryView), Line 161-240 (ClipboardHistoryViewModel)

---

## Data Layer

### Core Data Model

**Entity**: `ClipItem`
**Codegen**: Category/Extension (auto-generates properties in separate file)

**Attributes:**

| Attribute     | Type        | Optional | Default | Description                           |
| ------------- | ----------- | -------- | ------- | ------------------------------------- |
| `id`          | UUID        | No       | -       | Unique identifier                     |
| `dateAdded`   | Date        | No       | -       | Timestamp of capture                  |
| `isPinned`    | Boolean     | No       | NO      | Pin status                            |
| `textContent` | Binary Data | No       | -       | Encrypted text (plain or RTF preview) |
| `rtfData`     | Binary Data | Yes      | -       | Encrypted RTF data (for pasting)      |
| `appBundleID` | String      | Yes      | -       | Source app identifier                 |
| `contentHash` | String      | No       | -       | SHA-256 for deduplication             |

**Indexes:**

- `dateAdded` (for sorting)
- `isPinned` (for filtering)
- `contentHash` (for deduplication)

**Uniqueness Constraint:**

- `contentHash` (prevents duplicates at database level)

**Auto-Generated Properties:**
Located in: `DerivedData/.../ClipItem+CoreDataProperties.swift`

```swift
extension ClipItem {
    @NSManaged public var appBundleID: String?
    @NSManaged public var contentHash: String?
    @NSManaged public var dateAdded: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var isPinned: Bool
    @NSManaged public var rtfData: Data?
    @NSManaged public var textContent: Data?
}
```

**Note**: Core Data auto-generates all properties as optional Swift types (e.g., `Data?`) even if marked as non-optional in the model. The actual optionality is enforced at the Core Data level, not the Swift type level. Required fields (`textContent`, `contentHash`, etc.) will cause validation errors if left nil at save time.

**Custom Extensions:**
Located in: `ClipVault/Models/ClipItem+Extensions.swift`

```swift
extension ClipItem {
    // Encryption/decryption helpers
    func getDecryptedText() -> String?
    func setEncryptedText(_ text: String) throws

    func getDecryptedRTF() -> Data?
    func setEncryptedRTF(_ data: Data) throws

    // Display helpers
    func getPreviewText(maxLength: Int = 60) -> String
    func getRelativeTimeString() -> String

    // Hashing
    static func computeHash(for data: Data) -> String
    static func computeHash(for string: String) -> String
}
```

**Fetch Requests:**

```swift
// All items (pinned first, then by date descending)
static func fetchAllRequest() -> NSFetchRequest<ClipItem> {
    let request = fetchRequest()
    request.sortDescriptors = [
        NSSortDescriptor(keyPath: \ClipItem.isPinned, ascending: false),
        NSSortDescriptor(keyPath: \ClipItem.dateAdded, ascending: false)
    ]
    return request
}

// By hash (deduplication)
static func fetchByHashRequest(hash: String) -> NSFetchRequest<ClipItem> {
    let request = fetchRequest()
    request.predicate = NSPredicate(format: "contentHash == %@", hash)
    request.fetchLimit = 1
    return request
}
```

---

## Security Implementation

### Encryption Architecture

**Algorithm**: AES-256-GCM (Advanced Encryption Standard with Galois/Counter Mode)

**Why AES-GCM?**

- **Authenticated Encryption**: Provides both confidentiality and authenticity
- **AEAD Mode**: Detects tampering automatically
- **Performance**: Hardware-accelerated on modern CPUs
- **Standard**: NIST-approved, widely trusted

**Key Management:**

1. **Key Generation** (first launch):

```swift
let key = SymmetricKey(size: .bits256) // 256-bit key
```

2. **Key Storage** (Keychain):

```swift
kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
// Key only accessible when device unlocked
// Key never syncs to iCloud or other devices
```

3. **Key Retrieval**:

```swift
// Check cache first
if let cachedKey = cachedKey {
    return cachedKey
}

// Load from Keychain
let keyData = try loadKeyFromKeychain()
let key = SymmetricKey(data: keyData)
cachedKey = key // Cache for performance
```

**Encryption Flow:**

```
┌─────────────┐
│ Plain Text  │
└──────┬──────┘
       │
       ▼
┌──────────────────────┐
│ Convert to Data      │
│ (UTF-8 encoding)     │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Get Encryption Key   │
│ (from Keychain)      │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ AES.GCM.seal()       │
│ (Generate nonce,     │
│  encrypt, generate   │
│  authentication tag) │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Combined Data:       │
│ [nonce | ciphertext  │
│  | auth tag]         │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Store in Core Data   │
│ (textContent, etc.)  │
└──────────────────────┘
```

**Decryption Flow:**

```
┌──────────────────────┐
│ Load Encrypted Data  │
│ from Core Data       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Get Encryption Key   │
│ (from cache/Keychain)│
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ AES.GCM.open()       │
│ (Extract nonce,      │
│  decrypt, verify     │
│  authentication tag) │
└──────┬───────────────┘
       │
       ▼  (if tag invalid)
       │  ❌ Throw error
       │  (data tampered)
       │
       ▼  (if tag valid)
┌──────────────────────┐
│ Decrypted Data       │
└──────┬───────────────┘
       │
       ▼
┌──────────────────────┐
│ Convert to String    │
│ (UTF-8 decoding)     │
└──────────────────────┘
```

**Security Properties:**

✅ **Confidentiality**: Data unreadable without key
✅ **Authenticity**: Tampering detected via authentication tag
✅ **Key Security**: Stored in Keychain, device-only access
✅ **Forward Secrecy**: No (same key used; acceptable for local storage)
✅ **Defense in Depth**: Multiple layers (app sandbox + encryption + keychain)

---

### Logging Security

**Privacy-Aware Logging:**

ClipVault uses Apple's unified logging system with privacy protections:

```swift
// ✅ SAFE: Logs metadata only, no clipboard content
AppLogger.clipboard.debug("Captured text (chars: \(count), app: \(bundleID, privacy: .public))")

// ❌ NEVER: Don't log actual clipboard content
// AppLogger.clipboard.debug("Content: \(clipboardText)")
```

**Key Privacy Features:**

1. **Automatic Redaction**: Dynamic data marked `.private` by default
2. **Explicit Public Marking**: Only non-sensitive data marked `.public`
3. **No Content Logging**: Only metadata (char count, byte count, item IDs)
4. **Truncated UUIDs**: Item IDs show first 8 chars only for correlation
5. **Debug-Only Logs**: Detailed logs only in debug builds

**What Gets Logged:**

✅ **Safe to log:**

- Lifecycle events (app start, stop)
- Operation counts (item count, character count)
- App bundle IDs (not sensitive)
- Error descriptions (already sanitized by system)
- Truncated UUIDs (first 8 chars)

❌ **Never logged:**

- Actual clipboard content (text, RTF data)
- Full item UUIDs
- Encryption keys
- User search queries (only length logged)
- Decrypted data

**Example Secure Logging:**

```swift
// Before capture
AppLogger.clipboard.info("Started monitoring (interval: 0.3s)")

// After capture - metadata only
let itemId = AppLogger.formatItemId(item.id)
AppLogger.clipboard.debug("Captured text (chars: \(string.count), app: \(bundleID ?? "unknown", privacy: .public))")

// Error handling
AppLogger.clipboard.error("Failed to save item: \(error.localizedDescription, privacy: .public)")
```

---

### Sensitive Content Filtering

**Pattern-Based Detection:**

**1. JWT Tokens:**

```swift
if content.hasPrefix("eyJ") && content.count > 50 {
    return true // Likely JWT
}
```

**2. SSH Private Keys:**

```swift
if content.contains("-----BEGIN") &&
   (content.contains("PRIVATE KEY") ||
    content.contains("RSA PRIVATE KEY") ||
    content.contains("OPENSSH PRIVATE KEY")) {
    return true
}
```

**3. Long Alphanumeric Tokens:**

```swift
// 20-200 chars, >90% alphanumeric
if trimmed.count >= 20 && trimmed.count <= 200 {
    let ratio = alphanumericCount / totalCount
    if ratio > 0.9 {
        return true // Likely API key/token
    }
}
```

**4. Credit Card Numbers:**

```swift
let digits = string.filter { $0.isNumber }
if digits.count >= 13 && digits.count <= 19 {
    // Basic Luhn algorithm check
    return true
}
```

**5. Password Patterns:**

```swift
if lowercased.hasPrefix("password:") ||
   lowercased.hasPrefix("pass:") ||
   lowercased.hasPrefix("pwd:") ||
   lowercased.hasPrefix("secret:") {
    return true
}
```

**Limitations:**

- Heuristic-based (not perfect detection)
- May have false positives/negatives
- User can disable via settings
- No regex for performance reasons

---

## User Interface

### Menu Bar Icon

**Implementation:**

```swift
statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
statusItem.button?.image = NSImage(systemSymbolName: "list.clipboard.fill",
                                   accessibilityDescription: "ClipVault")
statusItem.button?.image?.isTemplate = true // Adapts to menu bar theme
```

**Interactions:**

- **Left Click**: `showMenu()` - Display clipboard history
- **Right Click**: `showContextMenu()` - Settings/Quit

**Button Action:**

```swift
button.action = #selector(statusBarButtonClicked)
button.sendAction(on: [.leftMouseUp, .rightMouseUp])

@objc private func statusBarButtonClicked() {
    let event = NSApp.currentEvent!
    if event.type == .rightMouseUp {
        showContextMenu()
    } else {
        showMenu()
    }
}
```

---

### Dynamic Menu Structure

```
┌────────────────────────────────────────┐
│  [Search Field: "Search clipboard..."] │  ← NSSearchField (280x24px, 12px padding)
├────────────────────────────────────────┤
│  📌 PINNED                             │  ← Header (disabled)
│  🔵 Item 1 (2h ago)                   │  ← ClipItem (🔵 = Slack icon)
│  📝 Item 2 (1d ago)                   │  ← ClipItem (📝 = Notes icon)
├────────────────────────────────────────┤
│  RECENT                                │  ← Header (disabled)
│  💻 Item 3 (Just now)                 │  ← ClipItem (💻 = VS Code icon)
│  🌐 Item 4 (5m ago)                   │  ← ClipItem (🌐 = Safari icon)
│  📝 Item 5 (12m ago)                  │  ← ClipItem (📝 = Notes icon)
│  └─ ... (up to 20 items)              │
├────────────────────────────────────────┤
│  View All...                           │  ← Action (opens filtering window)
│  Settings...                           │  ← Action
└────────────────────────────────────────┘
```

**Note**: Icons shown as emoji for illustration; actual implementation uses native macOS app icons fetched via `NSWorkspace.shared.icon(forFile:)`

**Context Menu (per item):**

```
┌─────────────────────┐
│  Copy               │  ← Shows "Copied!" notification
│  Paste              │  ← Shows "Pasted!" notification
├─────────────────────┤
│  Pin / Unpin        │
├─────────────────────┤
│  Delete             │
└─────────────────────┘
```

---

## Notification System

### Visual Notification Design

**Purpose**: Provide instant visual feedback for copy/paste actions

**Components:**

1. **NotificationManager**: Singleton coordinator
2. **NotificationState**: ObservableObject for state management
3. **CopyNotificationView**: SwiftUI view
4. **NSPanel**: Overlay display container

**Display Characteristics:**

- **Position**: Center of main screen
- **Size**: 200x80 (dynamic based on content)
- **Background**: Black with 85% opacity
- **Border**: White with 20% opacity, 1px width
- **Shadow**: Soft shadow (20px radius, 0.3 opacity)
- **Icon**: Checkmark circle (SF Symbol)
- **Animation**: Spring (0.3s response, 0.7 damping)
- **Duration**: 1.5 seconds before auto-dismiss

**Integration Points:**

- AppDelegate.clipItemSelected() → Copy action
- AppDelegate.copyItemToPasteboard() → Context menu copy
- AppDelegate.pasteItem() → Context menu paste
- ClipboardHistoryView.copyToClipboard() → View All copy

**Performance:**

- Non-blocking (asyncAfter for display)
- Minimal CPU overhead
- Click-through (ignoresMouseEvents)
- Never blocks user interaction

---

## Key Algorithms & Flows

### 1. Clipboard Capture Flow

```
┌──────────────────────────┐
│ Timer fires (300ms)      │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Check changeCount        │
└────────┬─────────────────┘
         │
         ▼  (changed)
┌──────────────────────────┐
│ Get frontmost app        │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Check app exclusions     │
└────────┬─────────────────┘
         │
         ▼  (not excluded)
┌──────────────────────────┐
│ Read pasteboard content  │
│ Priority: RTF → Text     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Check content filter     │
│ (if text content)        │
└────────┬─────────────────┘
         │
         ▼  (not sensitive)
┌──────────────────────────┐
│ Compute SHA-256 hash     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Check for duplicate hash │
└────────┬─────────────────┘
         │
         ├─ (exists) → Update timestamp
         │
         └─ (new) ──────────┐
                            ▼
                   ┌──────────────────────────┐
                   │ Create ClipItem entity   │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Encrypt content          │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Save to Core Data        │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Enforce max items limit  │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Invoke callback          │
                   │ onNewClipDetected?()     │
                   └──────────────────────────┘
```

---

### 2. Search Algorithm

**Naive Approach** (Current):

```swift
func searchItems(query: String) throws -> [ClipItem] {
    let allItems = try fetchAllItems()
    let lowercasedQuery = query.lowercased()

    return allItems.filter { item in
        if let text = item.getDecryptedText() {
            return text.lowercased().contains(lowercasedQuery)
        }
        return false
    }
}
```

**Performance:**

- Time Complexity: O(n·m) where n=items, m=avg content length
- Space Complexity: O(n)
- Typical: ~20-50ms for 100 items

**Limitations:**

- Decrypts all items (no index)
- Searches only plain text content (RTF preview text is searchable)
- Substring matching only (no fuzzy matching)

**Future Optimization:**

- Full-text search index (encrypted)
- Fuzzy matching (Levenshtein distance)

---

### 3. Deduplication Strategy

**Hash Function**: SHA-256

**Implementation:**

```swift
static func computeHash(for data: Data) -> String {
    let hash = SHA256.hash(data: data)
    return hash.compactMap { String(format: "%02x", $0) }.joined()
}
```

**Deduplication Logic:**

```swift
// Before creating new item
let hash = computeHash(for: content)

if let existingItem = try? fetchItemByHash(hash) {
    existingItem.dateAdded = Date() // Update timestamp
    try context.save()
    return existingItem
}

// Otherwise create new item with this hash
```

**Database Constraint:**

```xml
<uniquenessConstraints>
    <uniquenessConstraint>
        <constraint value="contentHash"/>
    </uniquenessConstraint>
</uniquenessConstraints>
```

**Edge Case Handling:**

- Hash collision: Virtually impossible (2^256 space)
- Same content, different format: RTF and plain text of same content = duplicate (hash based on plain text)

---

### 4. Auto-Paste Mechanism

```
┌──────────────────────────┐
│ User clicks clip item    │
│ (with auto-paste enabled)│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Write item to pasteboard │
│ (decrypt + write)        │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Wait 50ms                │
│ (ensure pasteboard ready)│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Check Accessibility      │
│ permissions              │
└────────┬─────────────────┘
         │
         ├─ (denied) → Show alert
         │
         └─ (granted) ──────┐
                            ▼
                   ┌──────────────────────────┐
                   │ Create CGEvent for       │
                   │ V key down + Command     │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Post event to system     │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Create CGEvent for       │
                   │ V key up + Command       │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Post event to system     │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Show "Pasted!"           │
                   │ notification             │
                   └────────┬─────────────────┘
                            │
                            ▼
                   ┌──────────────────────────┐
                   │ Active app receives ⌘V  │
                   │ and pastes content       │
                   └──────────────────────────┘
```

**Timing Considerations:**

- 50ms delay: Ensures pasteboard propagation
- Too short: Paste may fail (stale pasteboard)
- Too long: Noticeable lag

---

### 5. Notification Display Flow

```
┌──────────────────────────┐
│ Copy/Paste action        │
│ triggered                │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ NotificationManager      │
│ .showCopiedNotification()│
│ or .showPastedNotification()│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Cancel existing timer    │
│ (if notification visible)│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Create/reuse NSPanel     │
│ with CopyNotificationView│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Update message           │
│ ("Copied!" / "Pasted!")  │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Position in screen center│
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Set isVisible = true     │
│ (triggers animation)     │
└────────┬─────────────────┘
         │
         ▼
┌──────────────────────────┐
│ Schedule hide timer      │
│ (1.5 seconds)            │
└────────┬─────────────────┘
         │
         │ (1.5s later)
         ▼
┌──────────────────────────┐
│ Set isVisible = false    │
│ (fade out animation)     │
└────────┬─────────────────┘
         │
         │ (0.3s later)
         ▼
┌──────────────────────────┐
│ orderOut(nil)            │
│ (hide panel)             │
└──────────────────────────┘
```

---

## Configuration & Setup

### Xcode Project Setup

**Targets:**

1. **ClipVault** (macOS App)
   - Deployment Target: macOS 12.0
   - Bundle ID: `com.clipvault.ClipVault` (adjust as needed)
   - Signing: Automatic or Manual

---

### Build Settings

**Swift Language Version:** 5.9
**Optimization Level (Debug):** None [-Onone]
**Optimization Level (Release):** Optimize for Speed [-O]

---

### Entitlements

**ClipVault/ClipVault.entitlements:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Required for app sandbox -->
    <key>com.apple.security.app-sandbox</key>
    <true/>

    <!-- User-selected file access (for browsing excluded apps) -->
    <key>com.apple.security.files.user-selected.read-only</key>
    <true/>
</dict>
</plist>
```

---

### Info.plist Configuration

**ClipVault/Info.plist:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Hide from Dock (menu bar app only) -->
    <key>LSUIElement</key>
    <true/>

    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2025</string>

    <key>LSApplicationCategoryType</key>
    <string>public.app-category.productivity</string>
</dict>
</plist>
```

**Key:** `LSUIElement` set to `true` removes dock icon and prevents app from appearing in Cmd+Tab switcher (menu bar only).

---

### Required Permissions

**Accessibility Access** (for auto-paste functionality):

- Navigate: System Settings → Privacy & Security → Accessibility
- Add ClipVault and toggle ON
- Required only if auto-paste on select is enabled

---

### Core Data Migration

**Current Model Version:** 1
**Migration Strategy:** Lightweight migration (automatic)

**Future Model Changes:**
If adding attributes/entities:

1. Editor → Add Model Version (in .xcdatamodeld)
2. Set new version as current
3. Core Data handles migration automatically for simple changes

**Complex Migrations:**
Require custom migration mapping models.

---

## Testing Strategy

### Manual Testing Checklist

**Clipboard Capture:**

- [ ] Plain text capture works
- [ ] RTF capture works (copy from TextEdit with formatting)
- [ ] RTF has priority over plain text
- [ ] Duplicate detection (copy same text twice)
- [ ] Source app icon appears correctly
- [ ] RTF content shows formatting icon indicator

**Exclusions:**

- [ ] Content filter blocks JWT tokens (test: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...`)
- [ ] Content filter blocks SSH keys
- [ ] Content filter blocks long alphanumeric strings
- [ ] Content filter blocks credit card patterns
- [ ] Password manager exclusion works (copy from 1Password)
- [ ] Custom app exclusion works via browse button

**Search:**

- [ ] Search updates on each keystroke
- [ ] Search finds text content (case-insensitive)
- [ ] Search finds RTF plain text content
- [ ] "No results" message appears for no matches
- [ ] Search field maintains focus during typing

**Menu Interactions:**

- [ ] Left click opens menu
- [ ] Right click opens context menu
- [ ] Click item copies to clipboard (auto-paste OFF)
- [ ] Click item copies and pastes (auto-paste ON)
- [ ] Context menu "Copy" works → Shows "Copied!" notification
- [ ] Context menu "Paste" works → Shows "Pasted!" notification
- [ ] Context menu "Pin/Unpin" toggles correctly
- [ ] Context menu "Delete" removes item

**Visual Notifications:**

- [ ] "Copied!" notification appears when copying
- [ ] "Pasted!" notification appears when pasting
- [ ] Notification appears in center of screen
- [ ] Notification auto-dismisses after 1.5 seconds
- [ ] Notification has spring animation
- [ ] Notification is click-through (doesn't block interaction)
- [ ] Multiple rapid copies update notification smoothly

**Pinning:**

- [ ] Pin moves item to PINNED section
- [ ] Pinned items appear at top with 📌 header
- [ ] Pinned items survive Clear All
- [ ] Unpin returns item to RECENT section

**Settings:**

- [ ] Settings window opens (550x500)
- [ ] General tab: Max items dropdown works (50-500)
- [ ] General tab: RTF capture toggle works
- [ ] General tab: Auto-paste toggle works
- [ ] General tab: Clear All History button shows confirmation
- [ ] Privacy tab: Content filter toggle works
- [ ] Privacy tab: Browse button opens app picker
- [ ] Privacy tab: Excluded apps show icons and names
- [ ] Privacy tab: Remove button works on excluded apps
- [ ] Privacy tab: Encryption status badge displays
- [ ] About tab: Shows app icon, version, copyright
- [ ] About tab: GitHub link opens in browser

**View All Window:**

- [ ] Opens with "View All..." menu item
- [ ] Table shows Preview, Time, App, Actions columns
- [ ] RTF indicator icon shows for RTF items
- [ ] App icons display correctly
- [ ] App filter dropdown populates with all source apps
- [ ] Selecting app in filter shows only items from that app
- [ ] "All Apps" option clears the filter
- [ ] Search field filters items
- [ ] Pin/Copy/Delete buttons work
- [ ] Copy button shows "Copied!" notification
- [ ] Results count displays correctly

**Encryption:**

- [ ] Clipboard items encrypted in Core Data (inspect .sqlite file)
- [ ] Decryption works on load
- [ ] Encryption key persists in Keychain

**Performance:**

- [ ] App launches quickly (<1s)
- [ ] Search responsive (<100ms)
- [ ] Notifications appear instantly (<50ms)
- [ ] No memory leaks (Activity Monitor)
- [ ] Reasonable CPU usage (<5%)

---

### Unit Testing (Future)

**Test Targets:**

**EncryptionManager:**

```swift
func testEncryptDecryptString() {
    let original = "Hello, World!"
    let encrypted = try! EncryptionManager.shared.encryptString(original)
    let decrypted = try! EncryptionManager.shared.decryptString(encrypted)
    XCTAssertEqual(original, decrypted)
}

func testEncryptDecryptData() {
    let original = Data("Test data".utf8)
    let encrypted = try! EncryptionManager.shared.encrypt(original)
    let decrypted = try! EncryptionManager.shared.decrypt(encrypted)
    XCTAssertEqual(original, decrypted)
}
```

**ExclusionManager:**

```swift
func testJWTDetection() {
    let jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ"
    XCTAssertTrue(ExclusionManager.shared.isLikelySensitive(content: jwt))
}

func testSSHKeyDetection() {
    let sshKey = "-----BEGIN RSA PRIVATE KEY-----\\nMIIEpAIBAAKCAQEA..."
    XCTAssertTrue(ExclusionManager.shared.isLikelySensitive(content: sshKey))
}
```

**ClipItemManager:**

```swift
func testSaveAndFetch() throws {
    let content = ClipContent.text("Test clipboard item")
    let item = try ClipItemManager.shared.saveClipItem(
        content: content,
        appBundleID: "com.test.app"
    )

    let items = try ClipItemManager.shared.fetchAllItems()
    XCTAssertTrue(items.contains(item))
}

func testDeduplication() throws {
    let content = ClipContent.text("Duplicate test")

    let item1 = try ClipItemManager.shared.saveClipItem(content: content, appBundleID: nil)
    let item2 = try ClipItemManager.shared.saveClipItem(content: content, appBundleID: nil)

    XCTAssertEqual(item1.id, item2.id) // Same item returned
}
```

**NotificationManager:**

```swift
func testNotificationDisplay() {
    let expectation = XCTestExpectation(description: "Notification displayed")

    NotificationManager.shared.showCopiedNotification()

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // Verify notification panel is visible
        expectation.fulfill()
    }

    wait(for: [expectation], timeout: 1.0)
}
```

---

## Known Issues & Limitations

### Current Limitations

1. **Search Cannot Index Encrypted Content**

   - Requires decrypting all items on each search
   - Performance degrades with >500 items
   - Searches only plain text content

2. **No iCloud Sync**

   - Clipboard history local to device
   - Users with multiple Macs have separate histories

3. **No Drag-and-Drop**

   - Cannot drag items from menu to other apps
   - Menu-based interaction only

4. **Limited Content Type Support**

   - Only text and RTF supported
   - No image or file URL capture
   - No HTML clipboard support

5. **Menu Bar Only**

   - No windowed interface option (though View All provides browsing)
   - Accessibility concerns for screen readers

6. **Single Device Encryption Key**

   - Key stored in Keychain (device-bound)
   - Restoring from Time Machine backup loses key
   - No key export/import mechanism

7. **No Global Keyboard Shortcuts**
   - Must click menu bar icon to access history
   - No hotkey support for quick access or paste last item

---

### Known Bugs

1. **Notification Panel Persistence**
   - Panel remains in memory after first display (performance optimization)
   - Minimal memory overhead (<1MB)

---

## Future Work

### Planned Features

**Phase 1 (Short-term):**

- [ ] Drag-and-drop support in menu
- [ ] Export/import clipboard history
- [ ] View All window enhancements (sorting, bulk actions)
- [ ] Clipboard statistics and analytics
- [ ] Customizable notification settings (position, duration, appearance)
- [ ] Notification sound effects (optional)

**Phase 2 (Mid-term):**

- [ ] Global keyboard shortcuts for quick access and paste last item
- [ ] Image capture with thumbnail previews (content type expansion)
- [ ] File URL capture with "Reveal in Finder" (content type expansion)
- [ ] iCloud sync with E2E encryption
- [ ] Full-text search index (encrypted)
- [ ] Snippet templates with variables
- [ ] Smart suggestions based on context
- [ ] AppleScript/JavaScript automation support

**Phase 3 (Long-term):**

- [ ] CLI tool for terminal access
- [ ] Browser extension (Chrome, Safari)
- [ ] Team sharing features (workspace)
- [ ] Clipboard analytics (most used, etc.)
- [ ] OCR for image content
- [ ] Natural language search

---

### Performance Optimizations

**Search Optimization:**

```swift
// Current: O(n·m) decryption on every search
// Future: Maintain in-memory cache of decrypted previews

private var decryptedCache: [UUID: String] = [:]

func searchItems(query: String) throws -> [ClipItem] {
    let allItems = try fetchAllItems()

    return allItems.filter { item in
        // Check cache first
        if let cached = decryptedCache[item.id!] {
            return cached.lowercased().contains(query.lowercased())
        }

        // Decrypt and cache
        if let text = item.getDecryptedText() {
            decryptedCache[item.id!] = text
            return text.lowercased().contains(query.lowercased())
        }

        return false
    }
}
```

**Menu Rendering Optimization:**

- Virtual scrolling for >100 items
- Lazy loading of menu items
- Async icon fetching

**Notification Optimization:**

- Panel pooling (reuse existing panel)
- Async positioning calculations
- Reduced animation overhead

**Database Optimization:**

- Add compound index: `(isPinned, dateAdded)`
- Periodic VACUUM to reclaim space
- Consider WAL mode for concurrency

---

### Architectural Improvements

**1. Modular Architecture:**

```
ClipVaultCore (Framework)
├── Encryption
├── Storage
├── Search
└── Filtering

ClipVaultUI (App)
├── Menu Bar Interface
├── Notification System
└── Settings Window

ClipVaultCLI (Tool)
└── Command-line Interface
```

**2. Dependency Injection:**
Replace singletons with protocol-based dependency injection for testability.

```swift
protocol ClipboardMonitoring {
    func startMonitoring()
    func stopMonitoring()
}

class AppDelegate {
    let clipboardMonitor: ClipboardMonitoring

    init(clipboardMonitor: ClipboardMonitoring = ClipboardMonitor.shared) {
        self.clipboardMonitor = clipboardMonitor
    }
}
```

**3. Error Handling Strategy:**
Implement custom error types with recovery suggestions.

```swift
enum ClipVaultError: LocalizedError {
    case encryptionFailed(reason: String)
    case databaseUnavailable(underlying: Error)
    case permissionDenied(permission: String)

    var errorDescription: String? { ... }
    var recoverySuggestion: String? { ... }
}
```

---

## Appendix

### Development Commands

**Build:**

```bash
xcodebuild -project ClipVault.xcodeproj -scheme ClipVault -configuration Debug build
```

**Run:**

```bash
open /Users/edd/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/ClipVault.app
```

**Clean:**

```bash
xcodebuild clean -project ClipVault.xcodeproj -scheme ClipVault
```

---

### Debugging Tips

**View Application Logs:**

ClipVault uses Apple's unified logging system. View logs in real-time or historically:

```bash
# Stream logs in real-time
log stream --predicate 'subsystem == "com.clipvault"'

# View last hour of logs
log show --predicate 'subsystem == "com.clipvault"' --last 1h

# View only errors
log show --predicate 'subsystem == "com.clipvault" AND messageType == error' --last 24h

# View clipboard operations only
log show --predicate 'subsystem == "com.clipvault" AND category == "clipboard"' --last 1h

# Enable debug logs (requires sudo, resets on reboot)
sudo log config --mode "level:debug" --subsystem com.clipvault
log stream --predicate 'subsystem == "com.clipvault"' --level debug
```

Or use **Console.app**:

1. Open Console.app
2. Filter with: `subsystem == "com.clipvault"`
3. Select specific categories: `category == "clipboard"`

**Enable Core Data SQL Logging:**

```
Edit Scheme → Run → Arguments → Add:
-com.apple.CoreData.SQLDebug 3
```

**Monitor Clipboard Changes:**

Add temporary debug logging:

```swift
AppLogger.clipboard.debug("Pasteboard changeCount: \(NSPasteboard.general.changeCount)")
```

**Inspect Keychain:**

```bash
security find-generic-password -a "com.clipvault.encryption.key"
```

**Check Accessibility Permissions:**

Add temporary debug logging:

```swift
let trusted = AXIsProcessTrusted()
AppLogger.clipboard.debug("Accessibility trusted: \(trusted)")
```

**Monitor Notification Display:**

Check notification logs:

```bash
log stream --predicate 'subsystem == "com.clipvault" AND category == "ui"' | grep -i notification
```

---

### Useful Resources

- [Apple Core Data Programming Guide](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/CoreData/)
- [CryptoKit Documentation](https://developer.apple.com/documentation/cryptokit)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)
- [AppKit NSStatusItem](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Accessibility API](https://developer.apple.com/documentation/applicationservices/accessibility)
- [OSLog & Unified Logging](https://developer.apple.com/documentation/os/logging)
- [Generating Log Messages from Your Code](https://developer.apple.com/documentation/os/logging/generating_log_messages_from_your_code)
- [GitHub Project](https://github.com/eddmann/ClipVault)

---

**Document Revision History:**

- v1.2 (2025-10-10): Added AppLogger infrastructure and unified logging system documentation
- v1.1 (2025-10-09): Updated to reflect actual implementation including NotificationManager system
- v1.0 (2025-10-09): Initial comprehensive documentation
