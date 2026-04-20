import AppKit
import KeyboardShortcuts
import SharedCore
import UIKitShared

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("Shadow Translate launched · v\(SharedCore.version, privacy: .public)")
        NSApp.setActivationPolicy(.accessory)

        KeyboardShortcuts.onKeyUp(for: .translatePopup) { [weak self] in
            self?.togglePopup()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    private func togglePopup() {
        if FloatingPanelController.shared.isVisible {
            FloatingPanelController.shared.hide()
        } else {
            FloatingPanelController.shared.show {
                TranslationPopupView()
            }
        }
    }
}