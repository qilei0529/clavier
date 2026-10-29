//
//  KeyTaperApp.swift
//  KeyTaper
//
//  Created by Qilei on 2026/10/29.
//

import SwiftUI

@main
struct KeyTaperApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environment(appState)
        } label: {
            Label {
                Text(appState.menuBarTitle)
            } icon: {
                Image(systemName: appState.hasAccessibilityPermission ? "keyboard" : "exclamationmark.triangle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}
