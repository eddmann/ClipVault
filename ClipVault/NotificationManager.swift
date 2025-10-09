//
//  NotificationManager.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import AppKit
import SwiftUI
import Combine

class NotificationManager {
    static let shared = NotificationManager()

    private var notificationPanel: NSPanel?
    private var hideTimer: Timer?
    private var hostingController: NSHostingController<NotificationWrapper>?
    private var notificationState: NotificationState?

    private init() {}

    /// Shows the "Copied!" notification in the center of the screen
    func showCopiedNotification() {
        showNotification(message: "Copied!")
    }

    /// Shows the "Pasted!" notification in the center of the screen
    func showPastedNotification() {
        showNotification(message: "Pasted!")
    }

    private func showNotification(message: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Cancel any existing hide timer
            self.hideTimer?.invalidate()

            // If panel already exists and is visible, update message and re-trigger animation
            if let panel = self.notificationPanel, panel.isVisible, let state = self.notificationState {
                state.message = message
                state.show()
                self.resetHideTimer()
                return
            }

            // Create the notification panel if it doesn't exist
            if self.notificationPanel == nil {
                self.createNotificationPanel()
            }

            // Update message
            self.notificationState?.message = message

            // Position in center of screen
            if let screen = NSScreen.main, let panel = self.notificationPanel {
                let screenFrame = screen.frame
                let panelFrame = panel.frame
                let x = screenFrame.midX - panelFrame.width / 2
                let y = screenFrame.midY - panelFrame.height / 2
                panel.setFrameOrigin(NSPoint(x: x, y: y))
            }

            // Show the panel
            self.notificationPanel?.orderFrontRegardless()
            self.notificationState?.show()

            // Set timer to hide
            self.resetHideTimer()
        }
    }

    private func createNotificationPanel() {
        // Create state
        let state = NotificationState()

        // Create wrapper view with state
        let wrapper = NotificationWrapper(state: state)
        let hostingController = NSHostingController(rootView: wrapper)
        hostingController.view.frame = NSRect(x: 0, y: 0, width: 200, height: 80)

        // Create panel
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 80),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )

        panel.contentView = hostingController.view
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        panel.ignoresMouseEvents = true
        panel.hasShadow = false
        panel.isMovable = false

        self.notificationPanel = panel
        self.hostingController = hostingController
        self.notificationState = state
    }

    private func resetHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.hideNotification()
        }
    }

    private func hideNotification() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // Fade out animation
            self.notificationState?.hide()

            // Close panel after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.notificationPanel?.orderOut(nil)
            }
        }
    }
}

// MARK: - Notification State

class NotificationState: ObservableObject {
    @Published var isVisible: Bool = false
    @Published var message: String = "Copied!"

    func show() {
        isVisible = true
    }

    func hide() {
        isVisible = false
    }
}

// MARK: - Wrapper View

struct NotificationWrapper: View {
    @ObservedObject var state: NotificationState

    var body: some View {
        CopyNotificationView(isVisible: $state.isVisible, message: state.message)
    }
}
