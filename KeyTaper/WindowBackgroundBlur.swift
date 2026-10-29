//
//  WindowBackgroundBlur.swift
//  KeyTaper
//

import AppKit
import Darwin

enum WindowBackgroundBlur {
    private static let setRadius: (@convention(c) (Int32, Int32, Int) -> Int32)? = {
        let libraries = [
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
        ]
        for path in libraries {
            guard let handle = dlopen(path, RTLD_LAZY) else { continue }
            guard let symbol = dlsym(handle, "CGSSetWindowBackgroundBlurRadius") else { continue }
            return unsafeBitCast(symbol, to: (@convention(c) (Int32, Int32, Int) -> Int32).self)
        }
        return nil
    }()

    private static let defaultConnection: (@convention(c) () -> Int32)? = {
        let libraries = [
            "/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight",
            "/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics",
        ]
        for path in libraries {
            guard let handle = dlopen(path, RTLD_LAZY) else { continue }
            guard let symbol = dlsym(handle, "CGSDefaultConnectionForThread") else { continue }
            return unsafeBitCast(symbol, to: (@convention(c) () -> Int32).self)
        }
        return nil
    }()

    static func apply(to window: NSWindow, radius: Int) {
        window.isOpaque = false
        guard let setRadius, let defaultConnection else { return }
        _ = setRadius(defaultConnection(), Int32(window.windowNumber), radius)
    }
}
