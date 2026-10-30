//
//  WindowBackgroundBlur.swift
//  KeyTaper
//

import AppKit
import SwiftUI

/// Backdrop blur clipped to the HUD shape only (not the outer shadow padding).
struct ScopedBackdropBlur: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.isEmphasized = true
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

/// Near-black HUD backdrop for the MenuBarExtra window.
struct MenuBarWindowBackground: View {
    var body: some View {
        ZStack {
            MenuBarVisualEffectBackground()
            Color.black.opacity(0.66)
        }
    }
}

private struct MenuBarVisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.blendingMode = .behindWindow
        view.state = .active
        view.appearance = NSAppearance(named: .darkAqua)
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = .hudWindow
        nsView.blendingMode = .behindWindow
        nsView.state = .active
        nsView.appearance = NSAppearance(named: .darkAqua)
    }
}
