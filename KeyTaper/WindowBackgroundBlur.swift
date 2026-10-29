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
