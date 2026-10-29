//
//  KeystrokeMonitor.swift
//  KeyTaper
//

import AppKit
import Foundation

/// Observes global key and mouse-down events. Callers decide how to count / display.
final class KeystrokeMonitor: @unchecked Sendable {
    private var monitor: Any?
    private let onEvent: @Sendable (NSEvent) -> Void

    init(onEvent: @escaping @Sendable (NSEvent) -> Void) {
        self.onEvent = onEvent
    }

    var isRunning: Bool {
        monitor != nil
    }

    @discardableResult
    func start() -> Bool {
        guard monitor == nil else { return true }
        guard AccessibilityPermission.isGranted else { return false }

        monitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown]
        ) { [onEvent] event in
            onEvent(event)
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
