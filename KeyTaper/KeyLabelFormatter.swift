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

    /// `flagsChanged` fires on both press and release; true when this modifier key is now down.
    static func isModifierPressed(in event: NSEvent) -> Bool {
        let flags = event.modifierFlags
        switch Int(event.keyCode) {
        case 56, 60: return flags.contains(.shift)      // ⇧
        case 59, 62: return flags.contains(.control)    // ⌃
        case 58, 61: return flags.contains(.option)     // ⌥
        case 55, 54: return flags.contains(.command)    // ⌘
        case 57: return flags.contains(.capsLock)       // ⇪
        default: return false
        }
    }

    /// Best-effort label for a stored physical keyCode (US ANSI layout).
    static func label(forKeyCode code: UInt16) -> String {
        if let known = specialLabels[Int(code)] {
            return known
        }
        if let letter = ansiCharacterKeys[Int(code)] {
            return letter
        }
        return "Key \(code)"
    }

    private static let specialLabels: [Int: String] = [
        36: "⏎", 48: "⇥", 49: "⎵", 51: "⌫", 53: "⎋",
        117: "⌦", 123: "←", 124: "→", 125: "↓", 126: "↑",
        115: "↖", 119: "↘", 116: "⇞", 121: "⇟",
        122: "F1", 120: "F2", 99: "F3", 118: "F4",
        96: "F5", 97: "F6", 98: "F7", 100: "F8",
        101: "F9", 109: "F10", 103: "F11", 111: "F12",
        54: "⌘", 55: "⌘", 56: "⇧", 60: "⇧",
        58: "⌥", 61: "⌥", 59: "⌃", 62: "⌃",
    ]

    /// US ANSI letter / digit / punctuation keyCodes → lowercase glyph.
    private static let ansiCharacterKeys: [Int: String] = [
        0: "a", 1: "s", 2: "d", 3: "f", 4: "h", 5: "g", 6: "z", 7: "x",
        8: "c", 9: "v", 11: "b", 12: "q", 13: "w", 14: "e", 15: "r",
        16: "y", 17: "t", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
        23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
        30: "]", 31: "o", 32: "u", 33: "[", 34: "i", 35: "p", 37: "l",
        38: "j", 39: "'", 40: "k", 41: ";", 42: "\\", 43: ",", 44: "/",
        45: "n", 46: "m", 47: ".", 50: "`",
    ]
}
