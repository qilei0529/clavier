//
//  KeystrokeMonitor.swift
//  KeyTaper
//

import AppKit
import Foundation

/// Counts global keyDown events only. Never inspects or stores key codes / characters.
final class KeystrokeMonitor: @unchecked Sendable {
    private var monitor: Any?
    private let onKeyDown: @Sendable () -> Void

    init(onKeyDown: @escaping @Sendable () -> Void) {
        self.onKeyDown = onKeyDown
    }

    var isRunning: Bool {
        monitor != nil
    }

    @discardableResult
    func start() -> Bool {
        guard monitor == nil else { return true }
        guard AccessibilityPermission.isGranted else { return false }

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [onKeyDown] _ in
            onKeyDown()
        }

        return monitor != nil
    }

    func stop() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }

    deinit {
        stop()
    }
}
