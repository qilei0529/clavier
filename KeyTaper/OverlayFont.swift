//
//  OverlayFont.swift
//  KeyTaper
//

import AppKit
import SwiftUI

enum OverlayFont: String, CaseIterable, Identifiable {
    case system
    case helveticaNeue
    case avenirNext
    case menlo
    case monaco
    case futura
    case gillSans
    case optima

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "SF Pro"
        case .helveticaNeue: return "Helvetica Neue"
        case .avenirNext: return "Avenir Next"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .futura: return "Futura"
        case .gillSans: return "Gill Sans"
        case .optima: return "Optima"
        }
    }

    /// PostScript / family name for NSFont lookup (nil = system).
    private var fontName: String? {
        switch self {
        case .system: return nil
        case .helveticaNeue: return "Helvetica Neue"
        case .avenirNext: return "Avenir Next"
        case .menlo: return "Menlo"
        case .monaco: return "Monaco"
        case .futura: return "Futura"
        case .gillSans: return "Gill Sans"
        case .optima: return "Optima"
        }
    }

    func font(size: CGFloat, weight: Font.Weight) -> Font {
        let nsWeight = Self.nsWeight(from: weight)

        guard let fontName else {
            return Font(NSFont.systemFont(ofSize: size, weight: nsWeight))
        }

        if let base = NSFont(name: fontName, size: size) {
            let descriptor = base.fontDescriptor.addingAttributes([
                .traits: [NSFontDescriptor.TraitKey.weight: nsWeight.rawValue]
            ])
            if let weighted = NSFont(descriptor: descriptor, size: size) {
                return Font(weighted)
            }
            return Font(base)
        }

        return Font(NSFont.systemFont(ofSize: size, weight: nsWeight))
    }

    private static func nsWeight(from weight: Font.Weight) -> NSFont.Weight {
        switch weight {
        case .ultraLight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        default: return .regular
        }
    }
}
