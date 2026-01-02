//
//  HiddenWindowView.swift
//  ClipVault
//
//  Created by Edd on 02/01/2026.
//

import SwiftUI

/// Notification to open settings from anywhere in the app
extension Notification.Name {
    static let openClipVaultSettings = Notification.Name("openClipVaultSettings")
}

/// Invisible view that keeps SwiftUI's lifecycle alive for the Settings scene.
/// This window is positioned off-screen and made completely invisible.
struct HiddenWindowView: View {
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 1, height: 1)
            .onReceive(NotificationCenter.default.publisher(for: .openClipVaultSettings)) { _ in
                openSettings()
            }
            .onAppear {
                // Find and hide the lifecycle window
                DispatchQueue.main.async {
                    for window in NSApp.windows where window.title == "ClipVaultLifecycle" {
                        // Make the keepalive window truly invisible and non-interactive
                        window.styleMask = [.borderless]
                        window.collectionBehavior = [.auxiliary, .ignoresCycle, .transient, .canJoinAllSpaces]
                        window.isExcludedFromWindowsMenu = true
                        window.level = .floating
                        window.isOpaque = false
                        window.alphaValue = 0
                        window.backgroundColor = .clear
                        window.hasShadow = false
                        window.ignoresMouseEvents = true
                        window.canHide = false
                        window.setContentSize(NSSize(width: 1, height: 1))
                        window.setFrameOrigin(NSPoint(x: -5000, y: -5000))
                        break
                    }
                }
            }
    }
}
