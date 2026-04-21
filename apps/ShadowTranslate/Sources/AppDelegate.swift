import AppKit
import InferenceKit
import KeyboardShortcuts
import SharedCore
import UIKitShared

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let inferenceEngine = InferenceEngine()

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("Shadow Translate launched · v\(SharedCore.version, privacy: .public)")
        NSApp.setActivationPolicy(.accessory)

        KeyboardShortcuts.onKeyUp(for: .translatePopup) { [weak self] in
            self?.togglePopup()
        }

        Task {
            do {
                Log.app.info("Starting MLX warm up")
                try await inferenceEngine.warmUp()
                Log.app.info("MLX warm up complete")
            } catch {
                Log.app.error("MLX warm up failed: \(error.localizedDescription)")
            }
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