import AppKit
import ApplicationServices
import SharedCore

public actor AXReplacer {
    public init() {}

    // MARK: - Read Selected Text

    /// Read the currently selected text from the frontmost application.
    public func readSelectedText() -> String? {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let err = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard err == .success else {
            Log.accessibility.warning("AXReplacer.readSelectedText · cannot get focused element: \(err.rawValue)")
            return nil
        }

        let element = focusedElement as! AXUIElement
        var selectedText: AnyObject?
        let textErr = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedText
        )
        guard textErr == .success else {
            Log.accessibility.warning("AXReplacer.readSelectedText · cannot get selected text: \(textErr.rawValue)")
            return nil
        }

        return selectedText as? String
    }

    // MARK: - Replace Selected Text

    /// Replace the currently selected text.
    /// Uses AX API first, falls back to clipboard+⌘V.
    public func replaceSelectedText(_ newText: String) async throws {
        if tryAXReplace(newText) { return }
        try await clipboardReplace(newText)
    }

    // MARK: - Check if Replace is Available

    /// Check if the focused element supports text replacement via AX.
    public func canReplaceDirectly() -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let err = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard err == .success else { return false }

        let element = focusedElement as! AXUIElement
        var settable: DarwinBoolean = false
        let result = AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable)
        return result == .success && settable.boolValue
    }

    // MARK: - Private: Track 1 (AX Direct Write)

    private func tryAXReplace(_ newText: String) -> Bool {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedElement: AnyObject?
        let err = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard err == .success else { return false }

        let element = focusedElement as! AXUIElement

        var settable: DarwinBoolean = false
        let checkResult = AXUIElementIsAttributeSettable(element, kAXSelectedTextAttribute as CFString, &settable)
        guard checkResult == .success && settable.boolValue else { return false }

        let result = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            newText as CFTypeRef
        )
        if result != .success {
            Log.accessibility.warning("AXReplacer.tryAXReplace · AXUIElementSetAttributeValue failed: \(result.rawValue)")
            return false
        }

        Log.accessibility.info("AXReplacer.tryAXReplace · replaced via AX API")
        return true
    }

    // MARK: - Private: Track 2 (Clipboard + ⌘V)

    private func clipboardReplace(_ newText: String) async throws {
        let pasteboard = NSPasteboard.general
        let previousContent = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(newText, forType: .string)

        try postCommandV()

        try await Task.sleep(for: .milliseconds(500))
        pasteboard.clearContents()
        if let previous = previousContent {
            pasteboard.setString(previous, forType: .string)
        }

        Log.accessibility.info("AXReplacer.clipboardReplace · replaced via clipboard+⌘V")
    }

    private func postCommandV() throws {
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(
            keyboardEventSource: source,
            virtualKey: 9, // V key
            keyDown: true
        )
        keyDown?.flags = .maskCommand
        let keyUp = CGEvent(
            keyboardEventSource: source,
            virtualKey: 9,
            keyDown: false
        )
        keyUp?.flags = .maskCommand

        guard let down = keyDown, let up = keyUp else {
            throw ShadowError.accessibilityDenied
        }

        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}