import Foundation
@preconcurrency import ApplicationServices
import SharedCore

public enum AXPermissionStatus {
    case granted
    case denied
    case notDetermined
}

nonisolated(unsafe) private let axPromptOptionKey: CFString =
    kAXTrustedCheckOptionPrompt.takeUnretainedValue()

public enum AccessibilityKit {
    public static let version = "0.1.0"

    /// Check if this process has Accessibility permissions.
    public static func checkPermission() -> AXPermissionStatus {
        let options = [axPromptOptionKey: false] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted { return .granted }

        let alreadyAsked = UserDefaults.standard.bool(forKey: "AXPermissionRequested")
        return alreadyAsked ? .denied : .notDetermined
    }

    /// Prompt the user to grant Accessibility permissions.
    @discardableResult
    public static func requestPermission() -> Bool {
        let options = [axPromptOptionKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if !trusted {
            UserDefaults.standard.set(true, forKey: "AXPermissionRequested")
        }
        return trusted
    }
}