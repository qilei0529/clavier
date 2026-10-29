//
//  KeycastOverlayController.swift
//  KeyTaper
//

import AppKit
import SwiftUI

@MainActor
final class KeycastOverlayController {
    private static let originXKey = "overlayOriginX"
    private static let originYKey = "overlayOriginY"

    private let appState: AppState
    private var panel: NSPanel?
    nonisolated(unsafe) private var moveObserver: NSObjectProtocol?

    init(appState: AppState) {
        self.appState = appState
        setupPanel()
        observeVisibility()
        syncVisibility()
    }

    func syncVisibility() {
        guard let panel else { return }
        if appState.isOverlayVisible {
            panel.orderFrontRegardless()
            WindowBackgroundBlur.apply(to: panel, radius: 4)
        } else {
            panel.orderOut(nil)
        }
    }

    private func setupPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 180, height: 84),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isOpaque = false
        // Clear window chrome; SwiftUI owns fill + continuous corner radius.
        // CGS blur (4pt) still composites through translucent content.
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.isMovableByWindowBackground = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true

        let rootView = KeycastOverlayView()
            .environment(appState)
        let hostingView = DraggableHostingView(rootView: rootView)
        hostingView.sizingOptions = [.intrinsicContentSize]
        panel.contentView = hostingView

        panel.setFrameOrigin(restoredOrigin(for: panel) ?? defaultOrigin(for: panel))
        WindowBackgroundBlur.apply(to: panel, radius: 4)
        self.panel = panel

        moveObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didMoveNotification,
            object: panel,
            queue: .main
        ) { [weak self] notification in
            guard let window = notification.object as? NSWindow else { return }
            Task { @MainActor in
                self?.persistOrigin(window.frame.origin)
            }
        }
    }

    private func observeVisibility() {
        withObservationTracking {
            _ = appState.isOverlayVisible
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.syncVisibility()
                self?.observeVisibility()
            }
        }
    }

    private func defaultOrigin(for panel: NSPanel) -> NSPoint {
        guard let screen = NSScreen.main else {
            return NSPoint(x: 80, y: 80)
        }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        return NSPoint(
            x: visible.maxX - size.width - 24,
            y: visible.minY + 24
        )
    }

    private func restoredOrigin(for panel: NSPanel) -> NSPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Self.originXKey) != nil,
              defaults.object(forKey: Self.originYKey) != nil
        else {
            return nil
        }

        let origin = NSPoint(
            x: defaults.double(forKey: Self.originXKey),
            y: defaults.double(forKey: Self.originYKey)
        )

        let probe = NSRect(origin: origin, size: panel.frame.size)
        let onScreen = NSScreen.screens.contains { $0.visibleFrame.intersects(probe) }
        return onScreen ? origin : nil
    }

    private func persistOrigin(_ origin: NSPoint) {
        UserDefaults.standard.set(origin.x, forKey: Self.originXKey)
        UserDefaults.standard.set(origin.y, forKey: Self.originYKey)
    }

    deinit {
        if let moveObserver {
            NotificationCenter.default.removeObserver(moveObserver)
        }
    }
}

/// SwiftUI hosting views swallow mouse events; this lets the panel drag by its background.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override var mouseDownCanMoveWindow: Bool { true }
}
