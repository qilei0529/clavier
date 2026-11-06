//
//  KeystrokeMonitor.swift
//  KeyTaper
//

import AppKit
import Foundation

enum MonitoredEventType: Sendable {
    case keyDown
    case flagsChanged
    case leftMouseDown
    case rightMouseDown
    case other
}

struct MonitoredEvent: Sendable {
    let type: MonitoredEventType
    let keyCode: UInt16
    let modifierFlagsRawValue: UInt
    let charactersIgnoringModifiers: String?
    let isARepeat: Bool

    init(_ event: NSEvent) {
        switch event.type {
        case .keyDown: type = .keyDown
        case .flagsChanged: type = .flagsChanged
        case .leftMouseDown: type = .leftMouseDown
        case .rightMouseDown: type = .rightMouseDown
        default: type = .other
        }
        keyCode = event.keyCode
        modifierFlagsRawValue = event.modifierFlags.rawValue
        charactersIgnoringModifiers = event.charactersIgnoringModifiers
        isARepeat = event.isARepeat
    }
}

/// Observes global key and mouse-down events. Callers decide how to count / display.
final class KeystrokeMonitor: @unchecked Sendable {
    private var monitor: Any?
    private let onEvent: @Sendable (MonitoredEvent) -> Void

    init(onEvent: @escaping @Sendable (MonitoredEvent) -> Void) {
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
            onEvent(MonitoredEvent(event))
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
