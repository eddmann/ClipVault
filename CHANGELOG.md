# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-01-20

### Changed

- Release workflow now extracts version and release notes automatically from CHANGELOG.md

## [1.1.0] - 2026-01-02

### Added

- Dark mode support with theme toggle on landing page
- Auto-inject latest release version on deploy
- Higher quality 1024px app icon for site logo
- Homebrew tap auto-update to release workflow

### Changed

- Redesigned landing page with Tailwind CSS
- Modernized search bar with rounded design
- Settings window now uses native Settings scene with VoiceScribe-style UI
- General tab settings grouped into logical sections
- Search bar fills entire menu width dynamically
- Use `.js-` prefix pattern for theme toggle

### Fixed

- Restored missing history limit options in settings

## [1.0.2] - 2025-11-26

### Changed

- Simplified release workflow to match other projects

## [1.0.1] - 2025-11-26

### Added

- Code signing and notarization to GitHub release workflow

## [1.0.0] - 2025-11-05

### Added

- Automatic clipboard monitoring with real-time capture
- AES-256-GCM encryption for all content at rest with keys in macOS Keychain
- Smart content filtering to auto-detect and exclude passwords, API keys, SSH keys, and credit cards
- Rich text support preserving bold, italic, colors, and formatting
- Source app tracking showing which app each item came from with native icons
- Pin important items to keep frequently used snippets at the top
- Real-time search to instantly filter clipboard history
- Auto-paste functionality for one-click paste without keyboard commands
- Launch at login setting
- Version info in Info.plist for About screen
- Unified logging infrastructure with AppLogger
- GitHub Pages deployment workflow

### Fixed

- Menu no longer steals focus when opened
- Auto-paste now restores focus to original app before pasting
- Data loss prevention in keychain key storage

### Changed

- Minimum macOS requirement lowered to 12.0 (Monterey)
- Search field bezel style changed to square
- Menu item labels improved for clarity
- README streamlined for GitHub with updated documentation

[1.1.1]: https://github.com/eddmann/ClipVault/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/eddmann/ClipVault/compare/v1.0.2...v1.1.0
[1.0.2]: https://github.com/eddmann/ClipVault/compare/v1.0.1...v1.0.2
[1.0.1]: https://github.com/eddmann/ClipVault/compare/v1.0.0...v1.0.1
[1.0.0]: https://github.com/eddmann/ClipVault/releases/tag/v1.0.0
