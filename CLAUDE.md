# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ClipVault is a secure, privacy-focused clipboard manager for macOS built with Swift, AppKit, and SwiftUI. It automatically captures clipboard history, encrypts all content at rest using AES-256-GCM, and provides instant visual feedback through animated notifications.

**Key Characteristics:**

- Menu bar-only app (no Dock icon - `LSUIElement: true` in Info.plist)
- Combines AppKit (menu bar interface) with SwiftUI (settings, notifications, View All window)
- All clipboard content encrypted using CryptoKit and stored in Core Data
- Supports RTF (rich text) and plain text with RTF taking priority

## Build Commands

### Standard Build and Run

```bash
# Build in Xcode
xcodebuild -project ClipVault.xcodeproj -scheme ClipVault -configuration Debug build

# Run from command line (after build)
open /Users/edd/Library/Developer/Xcode/DerivedData/.../Build/Products/Debug/ClipVault.app

# Clean build
xcodebuild clean -project ClipVault.xcodeproj -scheme ClipVault
```

### Running in Xcode

Use Xcode's Run button (⌘R). The app appears only in the menu bar (no Dock icon).

## High-Level Architecture

### Layered Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                      │
│  (AppDelegate, SettingsView, NSMenu, NSStatusItem,          │
│   ClipboardHistoryView, NotificationManager)                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                       │
│  (ClipboardMonitor, ExclusionManager, PasteHelper)          │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                      Data Layer                              │
│  (ClipItemManager, Core Data Stack)                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│                  Infrastructure Layer                        │
│  (EncryptionManager, SettingsManager, Keychain)             │
└─────────────────────────────────────────────────────────────┘
```

### Critical Design Patterns

1. **Singleton Pattern**: All manager classes use `shared` instances
2. **Observer Pattern**: Clipboard monitoring via callbacks, NotificationCenter for search field
3. **Repository Pattern**: ClipItemManager abstracts Core Data access
4. **MVVM**: SwiftUI views (SettingsView, ClipboardHistoryView) use ViewModels

### Key Architectural Decisions

**AppKit + SwiftUI Hybrid:**

- AppDelegate creates NSStatusItem and manages NSMenu (AppKit)
- Settings window, View All window, and notifications use SwiftUI
- Bridge via NSHostingController

**Polling-Based Clipboard Monitoring:**

- Timer checks NSPasteboard.general.changeCount every 300ms
- NOT event-driven (macOS has no clipboard change notification API)

**Encryption Architecture:**

- AES-256-GCM via CryptoKit
- Symmetric key stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Key cached in memory for performance
- All clipboard content encrypted at rest in Core Data

## Critical Data Flow: Clipboard Capture

This is the most important flow to understand when modifying clipboard handling:

```
Timer (300ms) → Check changeCount → Get frontmost app bundle ID
                    ↓
        Check app exclusions → Read pasteboard (RTF priority → Plain text)
                    ↓
        Check content filter → Compute SHA-256 hash
                    ↓
        Check for duplicate → Create/Update ClipItem
                    ↓
        Encrypt content → Save to Core Data → Enforce max items limit
```

**Important**: RTF has PRIORITY over plain text. If RTF data exists and capture is enabled, it's used. Plain text is only captured if RTF is not available. This preserves formatting like bold, italic, and colors.

## Key Files and Their Roles

### Core Application

- **ClipVaultApp.swift**: SwiftUI app entry point with `@NSApplicationDelegateAdaptor`
- **AppDelegate.swift**: Main controller - creates menu bar UI, handles all menu interactions
- **Info.plist**: Contains `LSUIElement: true` (menu bar only, no Dock icon)

### Managers (All Singletons)

- **ClipboardMonitor.swift**: Polls clipboard every 300ms, triggers captures
- **ClipItemManager.swift**: Core Data repository - all CRUD operations, encryption coordination
- **EncryptionManager.swift**: AES-GCM encryption/decryption, Keychain key management
- **ExclusionManager.swift**: Two-layer filtering (app-based + content pattern matching)
- **SettingsManager.swift**: UserDefaults wrapper for preferences
- **PasteHelper.swift**: Auto-paste via CGEvent synthesis (requires Accessibility permissions)
- **NotificationManager.swift**: Visual on-screen notifications ("Copied!", "Pasted!")

### Views (SwiftUI)

- **SettingsView.swift**: Tabbed settings (General, Privacy, About) with SettingsViewModel
- **ClipboardHistoryView.swift**: View All window with table, search, app filtering
- **CopyNotificationView.swift**: Animated notification overlay (center screen, 1.5s auto-dismiss)

### Models

- **ClipItem+Extensions.swift**: Core Data model extensions with encryption helpers

### Data Model

- **ClipVault.xcdatamodeld**: Core Data schema
  - ClipItem entity with encrypted `textContent` and `rtfData`
  - Attributes: id (UUID), dateAdded (Date), isPinned (Bool), appBundleID (String), contentHash (String)
  - Uniqueness constraint on contentHash for deduplication

## Important Implementation Details

### Menu Bar Interactions

- **Left Click**: Opens main menu with clipboard history
- **Right Click**: Opens context menu (Settings, Quit)
- Handled in `AppDelegate.statusBarButtonClicked()`

### Search Implementation

- NSSearchField in menu updates via NotificationCenter
- Decrypts items in memory for matching (no encrypted index)
- Case-insensitive substring matching
- Updates menu in real-time by removing/rebuilding results section

### RTF Content Priority

```swift
// ClipboardMonitor.captureClipboard()
// Priority 1: RTF (preserves formatting)
if settings.captureRTF, let rtfData = pasteboard.data(forType: .rtf), !rtfData.isEmpty {
    // Extract plain text from RTF for preview and search
    // Store BOTH plain text and RTF data
}
// Priority 2: Plain text (only if RTF not available)
else if settings.captureText, let string = pasteboard.string(forType: .string) {
    // ...
}
```

### Visual Notifications

- Center-screen overlay using NSPanel with `.nonactivatingPanel` style
- SwiftUI-based view (CopyNotificationView) via NSHostingController
- Spring animation: response 0.3, damping 0.7
- Auto-dismisses after 1.5 seconds
- Click-through (ignoresMouseEvents: true)
- Level: `.statusBar` (appears above most windows)

### Source App Tracking

Every clipboard item records `appBundleID` of the frontmost app:

```swift
let frontmostApp = NSWorkspace.shared.frontmostApplication
let appBundleID = frontmostApp?.bundleIdentifier
```

Used for:

- Displaying app icons in menu and View All window
- App-based exclusions
- Filtering by source app in View All window

### Auto-Paste Mechanism

1. Write item to pasteboard
2. Wait 50ms (ensures pasteboard updated)
3. Check Accessibility permissions
4. Synthesize ⌘V keypress via CGEvent API
5. Show "Pasted!" notification

Requires Accessibility permissions: System Settings → Privacy & Security → Accessibility

## Sensitive Content Filtering

Pattern-based detection (heuristic, not perfect):

1. **JWT tokens**: Starts with "eyJ", length > 50
2. **SSH keys**: Contains "-----BEGIN" + "PRIVATE KEY"
3. **API keys**: 20-200 chars, >90% alphanumeric
4. **Credit cards**: 13-19 digits with basic Luhn check
5. **Password patterns**: Prefixes like "password:", "pwd:", "secret:"

Implemented in `ExclusionManager.isLikelySensitive()`

## Common Development Scenarios

### Adding a New Manager

1. Create singleton with `static let shared = ManagerName()`
2. Private `init()` to enforce singleton
3. Add to infrastructure layer (for core services) or business logic layer
4. Document in IMPLEMENTATION_GUIDE.md

### Modifying Core Data Model

1. Editor → Add Model Version in .xcdatamodeld
2. Set new version as current
3. Core Data handles lightweight migration automatically
4. For complex changes, create mapping model

### Adding Notification Integration

```swift
// In the action handler
NotificationManager.shared.showCopiedNotification()  // or showPastedNotification()
```

### Debugging Clipboard Issues

```swift
// In ClipboardMonitor
print("Pasteboard changeCount: \(NSPasteboard.general.changeCount)")
print("Frontmost app: \(NSWorkspace.shared.frontmostApplication?.bundleIdentifier ?? "unknown")")
```

### Testing Encryption

```bash
# View Keychain entry
security find-generic-password -a "com.clipvault.encryption.key"

# Enable Core Data SQL logging
# Edit Scheme → Run → Arguments → Add:
# -com.apple.CoreData.SQLDebug 3
```

## Security Considerations

1. **All encryption/decryption happens in EncryptionManager** - never bypass this
2. **Decrypted content only exists in memory temporarily** - never persist unencrypted
3. **Key retrieval is cached for performance** - cleared when app terminates
4. **Content filtering is enabled by default** - respect user's privacy settings
5. **Accessibility permissions required only for auto-paste** - graceful degradation without it

## File Organization

```
ClipVault/
├── Managers/           # All singleton business logic classes
├── Models/            # Core Data extensions
├── Views/             # SwiftUI views
├── Assets.xcassets/   # App icon and images
├── ClipVault.xcdatamodeld/  # Core Data schema
├── ClipVaultApp.swift # SwiftUI app entry
├── AppDelegate.swift  # AppKit app delegate (menu bar)
├── Info.plist        # LSUIElement, copyright, category
└── ClipVault.entitlements  # Sandbox, file access

Root/
├── PRODUCT_REQUIREMENTS.md    # Detailed PRD with all features
├── IMPLEMENTATION_GUIDE.md    # Comprehensive technical docs
└── ClipVault.xcodeproj       # Xcode project
```

## Settings Storage

Managed by `SettingsManager` wrapping UserDefaults:

**General:**

- `maxHistoryItems`: 50-500 (default 100)
- `captureRTF`: Bool (default true) - Exposed in UI as "Capture Rich Text Formatting"
- `captureText`: Bool (default true) - Internal flag, not in UI
- `autoPasteOnSelect`: Bool (default false)

**Privacy:**

- `contentFilterEnabled`: Bool (default true)
- `excludedAppBundleIDs`: [String] (default [])

## Performance Characteristics

- **Startup time**: < 1 second
- **Clipboard polling**: 300ms interval (low CPU overhead)
- **Search response**: ~20-50ms for 100 items (decrypts all in memory)
- **Memory usage**: < 50MB typical (100 items)
- **Notification latency**: < 50ms (instant visual feedback)

## Known Limitations

1. **Polling-based monitoring** - 300ms interval may miss very rapid clipboard changes
2. **No encrypted search index** - must decrypt all items to search
3. **Content types**: Only text and RTF supported (no images, files, HTML)
4. **No global keyboard shortcuts** - must click menu bar icon
5. **Single-device encryption key** - stored in Keychain, not synced

## References

- **Detailed architecture**: See IMPLEMENTATION_GUIDE.md (2088 lines)
- **Feature specifications**: See PRODUCT_REQUIREMENTS.md (515 lines)
- **Core Data model**: ClipVault.xcdatamodeld/ClipVault.xcdatamodel/contents
- **GitHub**: https://github.com/eddmann/ClipVault
