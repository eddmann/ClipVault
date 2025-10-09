# ClipVault - Product Requirements Document (PRD)

**Version:** 1.1
**Last Updated:** October 9, 2025
**Status:** Implemented

---

## Executive Summary

ClipVault is a secure, privacy-focused clipboard manager for macOS that automatically captures, encrypts, and organizes clipboard history. Unlike traditional clipboard managers, ClipVault prioritizes security by encrypting all clipboard content at rest using AES-GCM encryption stored in the system Keychain. The application provides instant visual feedback through animated on-screen notifications and offers source app tracking with native macOS app icons.

## Product Vision

To provide macOS users with a powerful yet secure clipboard management solution that enhances productivity without compromising privacy or security, featuring intuitive visual feedback and seamless integration with the macOS experience.

## Target Audience

### Primary Users
- **Developers & Engineers**: Frequently copy code snippets, API keys, and configurations
- **Content Creators**: Managing multiple text blocks and formatted content
- **Privacy-Conscious Users**: Need clipboard history but concerned about data security
- **Power Users**: Need quick access to clipboard history and workflow automation

### User Personas

**Persona 1: Security-Aware Developer (Alex)**
- Works with sensitive credentials and API keys daily
- Needs clipboard history but concerned about credential exposure
- Values encryption and smart filtering
- Uses multiple applications throughout the day

**Persona 2: Content Manager (Jordan)**
- Manages social media, blogs, and marketing materials
- Frequently copies text and formatted content between applications
- Needs quick search and retrieval of past clipboard items
- Values visual organization and easy access

## Core Features

### 1. Automatic Clipboard Monitoring
**Priority:** P0 (Must Have)

**Description:**
Continuously monitors the system clipboard and automatically captures new content in real-time.

**User Value:**
- No manual intervention required
- Never lose clipboard content again
- Works transparently in the background

**Capabilities:**
- Polls system clipboard every 300ms for changes
- Supports multiple content types: RTF (rich text formatting) and plain text
- **Priority order: RTF → Plain Text** (preserves formatting when available)
- Detects and prevents duplicate entries using SHA-256 hashing
- Captures source application bundle ID for context

### 2. Military-Grade Encryption
**Priority:** P0 (Must Have)

**Description:**
All clipboard content is encrypted at rest using AES-GCM authenticated encryption with keys stored securely in the macOS Keychain.

**User Value:**
- Clipboard history remains private even if storage is compromised
- Peace of mind when handling sensitive information
- Meets enterprise security standards

**Technical Details:**
- AES-256-GCM encryption
- Symmetric key stored in Keychain with `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`
- Encryption/decryption happens on-the-fly during storage/retrieval
- Per-device keys (not synced)

### 3. Smart Sensitive Content Filtering
**Priority:** P0 (Must Have)

**Description:**
Automatically detects and excludes likely sensitive content from being captured.

**User Value:**
- Prevents accidental storage of passwords, API keys, credit cards
- Reduces risk of credential leakage
- Works automatically without user configuration

**Detection Patterns:**
- JWT tokens (eyJ... prefix)
- SSH private keys (-----BEGIN patterns)
- Long alphanumeric strings (20-200 chars, likely API keys/tokens)
- Credit card numbers (13-19 digit sequences with basic Luhn check)
- Password field patterns (password:, pwd:, secret: prefixes)

### 4. Application-Based Exclusions
**Priority:** P0 (Must Have)

**Description:**
Excludes clipboard captures from specific applications (e.g., password managers, banking apps).

**User Value:**
- Enhanced privacy for sensitive applications
- Prevents password manager content from entering history
- User-customizable exclusion list via app browser

**Default Excluded Apps:**
- 1Password (com.agilebits.onepassword7, com.agilebits.onepassword-osx)
- LastPass (com.lastpass.lastpassmacdesktop)
- Bitwarden (com.bitwarden.desktop)
- KeePassXC (org.keepassx.keepassxc)
- Keychain Access (com.apple.keychainaccess)

### 5. Menu Bar Interface
**Priority:** P0 (Must Have)

**Description:**
Lightweight menu bar application with instant access to clipboard history via status bar icon.

**User Value:**
- Minimal screen real estate usage (no dock icon)
- Quick access from any application
- Non-intrusive design

**Interface Elements:**
- **Icon**: Clipboard list icon (`list.clipboard.fill`)
- **Left Click**: Opens main clipboard history menu
- **Right Click**: Settings and quit options
- **Search Field**: Real-time filtering as you type
- **Item Display**: Shows preview text, time stamp, and source app icon
- **Sections**: Pinned items at top, followed by recent items

### 6. Real-Time Search & Filtering
**Priority:** P0 (Must Have)

**Description:**
Search through clipboard history with instant results as you type.

**User Value:**
- Quickly find specific clipboard items from potentially hundreds of entries
- No need to scroll through long lists
- Works on decrypted content in memory

**Search Capabilities:**
- Case-insensitive matching
- Searches text content (including RTF plain text)
- Updates results immediately on each keystroke
- Maintains focus in search field during typing
- Shows "No results found" message when no matches

### 7. Pin Important Items
**Priority:** P1 (Should Have)

**Description:**
Users can pin frequently used clipboard items to keep them at the top of the list permanently.

**User Value:**
- Quick access to commonly used snippets
- Items persist through history cleanup
- Organize important content

**Behavior:**
- Pinned items appear in dedicated "📌 PINNED" section
- Survive "Clear All" operations (only clears unpinned items)
- Can be unpinned at any time
- Up to 10 pinned items shown in menu

### 8. Visual Copy/Paste Notifications
**Priority:** P1 (Should Have)

**Description:**
Animated on-screen notifications provide instant visual feedback when copying or pasting clipboard items.

**User Value:**
- Immediate confirmation of copy/paste actions
- Professional, non-intrusive design
- Reduces uncertainty about whether action succeeded

**Implementation:**
- Center-screen overlay notification
- "Copied!" message when item copied to clipboard
- "Pasted!" message when item auto-pasted
- Animated appearance with spring animation
- Auto-dismisses after 1.5 seconds
- Checkmark icon with semi-transparent dark background
- Ignores mouse events (click-through)

**Technical Details:**
- Uses NSPanel with `.nonactivatingPanel` style
- SwiftUI-based notification view (CopyNotificationView)
- NotificationManager singleton coordinates display
- Level: `.statusBar` (appears above most windows)
- Spring animation: response 0.3, damping 0.7

### 9. Auto-Paste Functionality
**Priority:** P1 (Should Have)

**Description:**
Optionally auto-paste selected clipboard items by simulating ⌘V keystroke.

**User Value:**
- One-click paste without manual keyboard command
- Faster workflow for repetitive pasting
- Optional per user preference

**Technical:**
- Uses CGEvent API to synthesize ⌘V keypress
- Requires Accessibility permissions
- 50ms delay ensures pasteboard is updated before paste
- Shows visual "Pasted!" notification on success

### 10. Configurable Settings
**Priority:** P1 (Should Have)

**Description:**
Comprehensive settings panel for customizing behavior and preferences, organized in a modern tabbed interface.

**Settings Categories:**

**General Tab:**
- Maximum history items: Dropdown selection (50, 100, 150, 200, 300, 400, 500; default: 100)
- Capture Rich Text Formatting: Toggle to preserve bold, italic, colors, and other RTF formatting (default: on)
- Auto-paste on select: Toggle to automatically paste when clicking an item (default: off)
- Clear All History: Button to permanently delete all non-pinned items with confirmation dialog

**Privacy Tab:**
- Content Filtering: Toggle to filter sensitive content like passwords, API keys, and credit card numbers (default: on)
- Excluded Applications: Browse and select apps to exclude from clipboard monitoring (user-friendly app picker with icons)
  - Shows app icon, name, and bundle ID
  - Remove button for each excluded app
  - Empty state with visual indicator
- Encryption Status: Green badge showing all content is encrypted at rest using AES-256-GCM

**About Tab:**
- App icon (128x128 with rounded corners and shadow)
- App name "ClipVault" (28pt semibold)
- Version number and build from Bundle
- Copyright "© 2025 Edd Mann"
- Description "Secure clipboard manager for macOS"
- GitHub project link button (https://github.com/eddmann/ClipVault)

### 11. Intelligent Deduplication
**Priority:** P2 (Nice to Have)

**Description:**
Automatically prevents duplicate entries by using content-based hashing.

**User Value:**
- Cleaner history without redundant entries
- Updates timestamp on duplicate detection
- Reduces storage space

**Implementation:**
- SHA-256 hash of content computed before storage
- Duplicate detection via Core Data uniqueness constraint
- Existing item timestamp updated on re-copy
- RTF and plain text of same content treated as duplicates (hash based on plain text)

### 12. Context Menu Actions
**Priority:** P1 (Should Have)

**Description:**
Right-click submenu on each clipboard item with common actions.

**Available Actions:**
- **Copy**: Place item back on system clipboard (shows "Copied!" notification)
- **Paste**: Copy to clipboard and auto-paste (shows "Pasted!" notification, requires permissions)
- **Pin/Unpin**: Toggle pinned status
- **Delete**: Remove item permanently

### 13. Source-Aware Clipboard History
**Priority:** P1 (Should Have)

**Description:**
Automatically captures and displays which application each clipboard item originated from, with visual app icons and filtering capabilities.

**User Value:**
- Visual context for where content originated
- Easier to remember and locate specific items from particular apps
- Filter clipboard history by source application
- Professional appearance with native macOS app icons

**Capabilities:**
- Records source app bundle ID for every clipboard item
- Displays native app icon next to each item in menu and View All window
- Filter by app in View All window (dropdown picker)
- Track clipboard usage patterns across applications
- "Unknown" shown for items without app bundle ID

**Use Cases:**
- "Show me everything I copied from Slack today"
- "Find that code snippet I copied from VS Code"
- "See all URLs I copied from Safari"

### 14. View All Window
**Priority:** P1 (Should Have)

**Description:**
Full-screen browsable window for advanced clipboard history management with table view and advanced filtering.

**User Value:**
- Browse larger clipboard history than fits in menu
- Sort and filter by multiple criteria
- Bulk management operations
- Better for working with many items

**Features:**
- SwiftUI Table with sortable columns:
  - **Preview**: Text preview with RTF indicator icon
  - **Time**: Relative time string (e.g., "2m ago")
  - **App**: Source app icon and name
  - **Actions**: Pin, Copy, Delete buttons
- Toolbar controls:
  - Search field for text filtering
  - App filter dropdown (shows all apps with clipboard items)
  - Refresh button
  - Results count display
- Window size: 900x600 (resizable)
- Real-time filtering as you type

---

## Non-Functional Requirements

### Performance
- **Startup Time**: < 1 second to launch and begin monitoring
- **Search Response**: < 100ms for search results update
- **Memory Usage**: < 50MB RAM for typical usage (100 items)
- **CPU Usage**: < 1% when idle, < 5% during active capture
- **Notification Display**: Instant visual feedback (<50ms)

### Security
- All clipboard content encrypted with AES-256-GCM
- Encryption keys stored in Keychain with device-only access
- No network transmission of clipboard data
- No telemetry or analytics collection
- Smart filtering of sensitive content enabled by default

### Reliability
- No clipboard content loss even if app crashes
- Graceful handling of Core Data migration errors
- Automatic recovery from invalid encryption states
- Safe concurrent access to clipboard history
- Notifications never block main thread

### Usability
- Native macOS look and feel (AppKit + SwiftUI)
- Follows Apple Human Interface Guidelines
- Keyboard-navigable interface
- Instant visual feedback for all actions
- VoiceOver accessibility (future enhancement)

### Compatibility
- **Minimum macOS Version**: macOS 12.0 (Monterey)
- **Architecture**: Universal Binary (Intel + Apple Silicon)
- **Xcode Version**: 15.0+
- **Swift Version**: 5.9+

---

## User Stories

### Story 1: Quick Search
**As a** developer
**I want to** search my clipboard history by typing keywords
**So that** I can quickly find and reuse a code snippet I copied earlier today

**Acceptance Criteria:**
- Search updates as I type each character
- Case-insensitive matching
- Shows only matching results
- Search field maintains focus
- Shows "No results found" when no matches

### Story 2: Secure Password Handling
**As a** security-conscious user
**I want to** ensure passwords never enter my clipboard history
**So that** I don't accidentally expose credentials

**Acceptance Criteria:**
- Content filter enabled by default
- Password patterns automatically excluded
- 1Password excluded from captures
- Visual confirmation in settings that encryption is active

### Story 3: Pin Frequently Used Items
**As a** content manager
**I want to** pin my email signature and common responses
**So that** they're always available at the top of my history

**Acceptance Criteria:**
- Right-click item and select "Pin"
- Pinned items appear in dedicated section at top with 📌 icon
- Pinned items survive "Clear All" operations
- Can unpin at any time

### Story 4: Visual Confirmation
**As a** user
**I want to** see immediate visual confirmation when I copy something
**So that** I know my action succeeded without checking manually

**Acceptance Criteria:**
- Animated "Copied!" notification appears in center of screen
- Notification auto-dismisses after 1.5 seconds
- Professional, non-intrusive design
- Works for both menu item clicks and context menu actions

### Story 5: Auto-Paste Workflow
**As a** power user
**I want to** auto-paste items when I click them
**So that** I can paste content faster without pressing ⌘V

**Acceptance Criteria:**
- Toggle in settings to enable auto-paste
- Clicking item copies to clipboard AND pastes
- Shows "Pasted!" notification instead of "Copied!"
- Clear prompt if Accessibility permissions needed
- Visual indication in settings when enabled

### Story 6: Exclude Banking App
**As a** privacy-focused user
**I want to** exclude my banking app from clipboard captures
**So that** account numbers and sensitive banking data never enters history

**Acceptance Criteria:**
- Can browse and select apps in settings via file picker
- Excluded apps listed with icons and removable
- Shows app icon, name, and bundle ID
- Remove button on each excluded app
- Immediate effect (no restart required)

### Story 7: Filter by Source App
**As a** developer
**I want to** filter my clipboard history to show only items from VS Code
**So that** I can quickly find code snippets without searching through chat messages and other content

**Acceptance Criteria:**
- View All window shows app filter dropdown
- Dropdown populated with all apps that have clipboard items
- Selecting an app filters the table to show only items from that app
- App icons visible in both menu and View All window
- "All Apps" option to clear filter

---

## Success Metrics

### Adoption Metrics
- **Downloads**: Track initial adoption rate
- **Daily Active Users**: Measure regular usage
- **Retention**: 30-day retention rate

### Usage Metrics
- **Clipboard Items Captured**: Average per user per day
- **Search Usage**: % of opens that use search
- **Pin Usage**: Average pinned items per user
- **Excluded Apps**: Average exclusions per user
- **Notification Views**: Number of visual notifications shown per session

### Quality Metrics
- **Crash Rate**: < 0.1% of sessions
- **Search Performance**: 95th percentile < 100ms
- **Notification Latency**: 95th percentile < 50ms
- **User Satisfaction**: NPS score (if collected)

---

## Future Enhancements

### Phase 2 (Next Release)
- [ ] Drag-and-drop support in menu
- [ ] Export/import clipboard history
- [ ] iCloud sync option (with end-to-end encryption)
- [ ] Image capture support with thumbnail previews (future expansion)
- [ ] File URL capture with "Reveal in Finder" action (future expansion)
- [ ] Customizable notification appearance

### Phase 3 (Long-term)
- [ ] Snippet templates with placeholders
- [ ] Smart clipboard suggestions based on context
- [ ] Browser extension integration
- [ ] Team sharing features (enterprise)
- [ ] Global keyboard shortcuts for menu access and paste last item
- [ ] Notification sound effects (optional)
- [ ] Custom notification positions

---

## Risks & Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Accessibility permission denial | High | Medium | Clear UI prompts with instructions; graceful degradation (copy-only mode); visual notifications work without permissions |
| Performance degradation with large history | Medium | Low | Pagination; virtual scrolling; enforce max items limit; notification system optimized for minimal overhead |
| Encryption key loss | High | Very Low | Keychain backup recommendations; clear user education |
| Conflict with other clipboard managers | Medium | Medium | Detection and user warning; safe co-existence mode |
| Notification blocking important content | Low | Low | Click-through notifications; high z-index; auto-dismiss; user can disable in settings (future) |

---

## Appendix

### Glossary
- **Clip Item**: A single entry in clipboard history
- **Pin**: Mark an item for permanent retention at top of list
- **Bundle ID**: Unique identifier for macOS applications
- **RTF**: Rich Text Format - preserves text styling like bold, italic, and colors
- **AES-GCM**: Advanced Encryption Standard with Galois/Counter Mode
- **Accessibility Permissions**: macOS security feature for input monitoring and auto-paste
- **Visual Notification**: Animated on-screen overlay providing action feedback

### References
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [NIST AES-GCM Specification](https://csrc.nist.gov/publications/detail/sp/800-38d/final)
- [macOS Security Guide](https://support.apple.com/guide/security/welcome/web)
- [GitHub Project](https://github.com/eddmann/ClipVault)
