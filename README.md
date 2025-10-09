<img src="site/logo.png" width="200">

# ClipVault

A secure, privacy-focused clipboard manager for macOS.

## Overview

ClipVault automatically captures, encrypts, and organizes your clipboard history. Unlike traditional clipboard managers, ClipVault prioritizes security by encrypting all clipboard content at rest using AES-256-GCM encryption stored in the system Keychain.

When active:

- All clipboard content is automatically captured and encrypted
- Rich text formatting (RTF) is preserved
- Source application tracking with native app icons
- Instant visual feedback with animated notifications
- Smart filtering prevents sensitive content from being captured

## Features

- Automatic clipboard monitoring - Captures all clipboard changes in real-time
- Military-grade encryption - AES-256-GCM encryption with keys stored securely in macOS Keychain
- Smart sensitive content filtering - Automatically detects and excludes passwords, API keys, credit cards, and SSH keys
- Application-based exclusions - Block clipboard captures from password managers and other sensitive apps
- Real-time search & filtering - Instantly search through clipboard history
- Pin important items - Keep frequently used snippets at the top permanently
- Visual copy/paste notifications - Animated on-screen feedback for copy and paste actions
- Auto-paste functionality - One-click paste without manual keyboard commands
- Source app tracking - See which app each clipboard item came from with native icons
- View All window - Browse and manage large clipboard history with advanced filtering
- Rich text support - Preserves bold, italic, colors, and other formatting

## Installation

1. Download the latest release
2. Unzip and move `ClipVault.app` to your Applications folder
3. **Right-click** the app and select **"Open"** (required for unsigned apps)

If you see "ClipVault is damaged and can't be opened", run this command in Terminal:

```bash
xattr -cr /Applications/ClipVault.app
```

Then launch the app normally.

## Usage

1. Click the clipboard icon in your menu bar to view your clipboard history
2. Search - Type in the search field to filter items instantly
3. Click an item - Copies it back to your clipboard (shows "Copied!" notification)
4. Right-click an item for actions:
   - Copy - Place item on clipboard
   - Paste - Copy and auto-paste (requires Accessibility permissions)
   - Pin/Unpin - Keep item at top permanently
   - Delete - Remove item from history

### Menu Bar Icon

- Clipboard icon = active and monitoring
- Items show preview text, timestamp, and source app icon
- Pinned items appear at the top with a 📌 indicator

### Settings

**Right-click the menu bar icon** and select "Settings" to configure:

#### General Tab

- Maximum history items - Set how many items to keep (50-500, default: 100)
- Capture Rich Text Formatting - Preserve bold, italic, colors, and other formatting
- Auto-paste on select - Automatically paste when clicking an item
- Clear All History - Permanently delete all non-pinned items

#### Privacy Tab

- Content Filtering - Automatically filter sensitive content like passwords and API keys (enabled by default)
- Excluded Applications - Select apps to exclude from clipboard monitoring (e.g., 1Password, LastPass, Bitwarden)
- Encryption Status - Visual confirmation that all content is encrypted at rest

#### About Tab

- App version and build information
- Copyright and description
- Link to GitHub project

### View All Window

Select **"View All Clipboard History"** from the menu to open the full management window:

- Browse all clipboard items in a sortable table
- Filter by source application
- Sort by time, preview, or app
- Quick actions: Pin, Copy, Delete
- Real-time search and filtering

## Use Cases

- Developers - Never lose code snippets, API keys are automatically filtered
- Content creators - Manage multiple text blocks with formatting preserved
- Privacy-conscious users - All clipboard content encrypted, password managers excluded
- Power users - Quick search and auto-paste for fast workflows
- Security professionals - Smart filtering prevents credential exposure

## Security & Privacy

- AES-256-GCM encryption - All clipboard content encrypted at rest
- Keychain storage - Encryption keys stored securely with device-only access
- No network transmission - Clipboard data never leaves your device
- No telemetry - Zero analytics or data collection
- Smart filtering - Automatically excludes passwords, tokens, SSH keys, and credit card numbers
- App exclusions - Block password managers and sensitive apps by default

## Requirements

- macOS 12.0 (Monterey) or later
- Universal Binary (Intel + Apple Silicon)

## Notes

- To use auto-paste functionality, grant Accessibility permissions when prompted (System Settings → Privacy & Security → Accessibility)
- The app runs in the menu bar only (no Dock icon)
- All data is stored locally on your device and never synced or transmitted

## Default Excluded Applications

ClipVault comes pre-configured to exclude common password managers:

- 1Password
- LastPass
- Bitwarden
- KeePassXC
- Keychain Access

You can add more excluded apps in Settings → Privacy → Excluded Applications.

## Project

For more information, source code, and issue reporting, visit:
https://github.com/eddmann/ClipVault
