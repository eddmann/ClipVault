//
//  ClipVaultApp.swift
//  ClipVault
//
//  Created by Edd on 09/10/2025.
//

import SwiftUI

@main
struct ClipVaultApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
