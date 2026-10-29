//
//  AppDelegate.swift
//  KeyTaper
//

import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private var overlayController: KeycastOverlayController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        overlayController = KeycastOverlayController(appState: appState)
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Counts are already debounced to disk; flush any pending write via quit path if used.
    }
}
