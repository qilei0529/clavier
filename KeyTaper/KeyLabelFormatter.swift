//
//  KeyLabelFormatter.swift
//  KeyTaper
//

import AppKit
import Foundation

enum KeyLabelFormatter {
    /// Key name only (modifiers are shown separately in the overlay chrome).
    static func keyName(for event: NSEvent) -> String? {
        switch Int(event.keyCode) {
        case 36: return "⏎"   // Return
        case 48: return "⇥"   // Tab
        case 49: return "⎵"   // Space
        case 51: return "⌫"   // Delete
        case 53: return "⎋"   // Escape
        case 117: return "⌦"  // Forward delete
        case 123: return "←"
        case 124: return "→"
        case 125: return "↓"
        case 126: return "↑"
        case 115: return "↖"  // Home
        case 119: return "↘"  // End
        case 116: return "⇞"  // Page Up
        case 121: return "⇟"  // Page Down
        case 122: return "F1"
        case 120: return "F2"
        case 99: return "F3"
        case 118: return "F4"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 100: return "F8"
        case 101: return "F9"
        case 109: return "F10"
        case 103: return "F11"
        case 111: return "F12"
        default:
            break
        }

        guard let raw = event.charactersIgnoringModifiers, !raw.isEmpty else {
            return nil
        }

        if raw == "\u{1b}" { return "⎋" }
        if raw == "\r" || raw == "\n" { return "⏎" }
        if raw == "\t" { return "⇥" }
        if raw == " " { return "⎵" }
        if raw == "\u{7f}" { return "⌫" }

        return raw
    }

    static func activeModifiers(from flags: NSEvent.ModifierFlags) -> NSEvent.ModifierFlags {
        flags.intersection([.shift, .control, .option, .command])
    }
}
