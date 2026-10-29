//
//  KeyTaperApp.swift
//  KeyTaper
//
//  Created by Qilei on 2026/10/29.
//

import SwiftUI

@main
struct KeyTaperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(appDelegate.appState)
        } label: {
            MenuBarLabel(appState: appDelegate.appState)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarLabel: View {
    @Bindable var appState: AppState

    var body: some View {
        Label {
            Text(appState.menuBarTitle)
        } icon: {
            Image(
                systemName: appState.hasAccessibilityPermission
                    ? "keyboard"
                    : "exclamationmark.triangle"
            )
        }
    }
}
