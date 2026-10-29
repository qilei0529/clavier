//
//  SecureInputDetector.swift
//  KeyTaper
//

import ApplicationServices
import Carbon
import Foundation

enum SecureInputDetector {
    /// True when the system secure event input is on, or the focused AX element is a secure text field.
    static var isActive: Bool {
        if IsSecureEventInputEnabled() {
            return true
        }
        return focusedElementIsSecureTextField()
    }

    private static func focusedElementIsSecureTextField() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedObject: CFTypeRef?
        let focusStatus = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedObject
        )
        guard focusStatus == .success, let focusedObject else { return false }

        let element = focusedObject as! AXUIElement

        if let role = stringAttribute(element, kAXRoleAttribute as CFString),
           role == (kAXTextFieldRole as String) || role == "AXSecureTextField"
        {
            if role == "AXSecureTextField" {
                return true
            }
            if let subrole = stringAttribute(element, kAXSubroleAttribute as CFString),
               subrole == (kAXSecureTextFieldSubrole as String)
            {
                return true
            }
        }

        return false
    }

    private static func stringAttribute(_ element: AXUIElement, _ attribute: CFString) -> String? {
        var value: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard status == .success, let value else { return nil }
        return value as? String
    }
}
