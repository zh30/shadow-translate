import AccessibilityKit
import AppKit
import KeyboardShortcuts
import SharedCore
import UIKitShared

@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()
    private let axReplacer = AXReplacer()
    private var onboardingController: OnboardingWindowController?
    private var defaultsObserver: NSObjectProtocol?
    private var configuredHotkeyMode: String?
    private lazy var deepLHotkeyMonitor = DeepLHotkeyMonitor { [weak self] in
        self?.togglePopup()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        Log.app.info("Shadow Translate launched · v\(SharedCore.version, privacy: .public)")
        NSApp.setActivationPolicy(.accessory)

        if KeyboardShortcuts.getShortcut(for: .translatePopup) == nil {
            KeyboardShortcuts.setShortcut(.init(.t, modifiers: [.command, .shift]), for: .translatePopup)
        }

        KeyboardShortcuts.onKeyUp(for: .translatePopup) { [weak self] in
            // 200 ms delay: give the user time to release all physical modifier keys
            // before we synthesise a new ⌘C event.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self?.togglePopup()
            }
        }
        configureHotkeyMode()
        defaultsObserver = NotificationCenter.default.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.configureHotkeyMode()
            }
        }

        onboardingController = OnboardingWindowController(appState: appState)
        FloatingPanelController.shared.configure(appState: appState)

        guard !Self.isRunningTests else {
            Log.app.info("AppDelegate.applicationDidFinishLaunching · skipping model warm-up under tests")
            return
        }

        Task {
            await appState.checkModelState()
            handleCurrentState()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let defaultsObserver {
            NotificationCenter.default.removeObserver(defaultsObserver)
        }
        deepLHotkeyMonitor.stop()
    }

    private static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    // MARK: - Hotkeys

    private func configureHotkeyMode() {
        let rawMode = UserDefaults.standard.string(forKey: "hotkeyMode") ?? HotkeyMode.simple.rawValue
        guard configuredHotkeyMode != rawMode else { return }
        configuredHotkeyMode = rawMode

        if rawMode == HotkeyMode.deepL.rawValue {
            _ = deepLHotkeyMonitor.start()
        } else {
            deepLHotkeyMonitor.stop()
        }
    }

    // MARK: - Popup

    private func togglePopup() {
        if FloatingPanelController.shared.isVisible {
            FloatingPanelController.shared.hide()
            return
        }

        Task {
            let selectedText = await readSelectedText()
            Log.app.info("AppDelegate.togglePopup · selected text length: \(selectedText.count)")

            await MainActor.run {
                FloatingPanelController.shared.show {
                    TranslationPopupView(initialText: selectedText)
                        .id(UUID())
                }
            }
        }
    }

    /// Read selected text from the frontmost application.
    /// Uses AX API first, falls back to clipboard+⌘C if AX fails.
    private func readSelectedText() async -> String {
        Log.app.info("readSelectedText started")

        // Track 1: AX API (zero side effects)
        if let axText = await axReplacer.readSelectedText(), !axText.isEmpty {
            Log.app.info("AX track succeeded, length: \(axText.count, privacy: .public)")
            return axText
        }
        Log.app.info("AX track failed or empty, trying clipboard")

        // Prompt for Accessibility permissions on first use so the AX track works next time
        let axStatus = AccessibilityKit.checkPermission()
        Log.app.info("AX permission status: \(String(describing: axStatus), privacy: .public)")
        if axStatus == .notDetermined {
            Log.app.info("Requesting Accessibility permission...")
            _ = AccessibilityKit.requestPermission()
        }

        // Track 2: Clipboard + ⌘C
        let previous = NSPasteboard.general.string(forType: .string)
        let sentinel = UUID().uuidString
        let previousChangeCount = NSPasteboard.general.changeCount
        Log.app.info("previous clipboard length: \(previous?.count ?? 0) changeCount: \(previousChangeCount)")

        // Write sentinel so we can detect whether ⌘C actually produced new content
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sentinel, forType: .string)
        let sentinelChangeCount = NSPasteboard.general.changeCount
        Log.app.info("sentinel written, changeCount: \(sentinelChangeCount)")

        await sendCommandC()

        // Poll changeCount for up to 2 s — more reliable than polling string value
        let startTime = Date()
        var copied: String?
        while Date().timeIntervalSince(startTime) < 2.0 {
            try? await Task.sleep(for: .milliseconds(100))
            let currentChangeCount = NSPasteboard.general.changeCount
            if currentChangeCount != sentinelChangeCount {
                let current = NSPasteboard.general.string(forType: .string)
                Log.app.info("clipboard changed, changeCount: \(currentChangeCount) length: \(current?.count ?? 0)")
                if let current, current != sentinel {
                    copied = current
                }
                break
            }
        }

        Log.app.info("after ⌘C clipboard length: \(copied?.count ?? 0)")

        // Restore clipboard
        NSPasteboard.general.clearContents()
        if let previous {
            NSPasteboard.general.setString(previous, forType: .string)
        }

        if let copied, !copied.isEmpty {
            Log.app.info("clipboard track succeeded, length: \(copied.count, privacy: .public)")
            return copied
        }

        // Track 3: AppleScript via System Events (different event mechanism)
        let previous2 = NSPasteboard.general.string(forType: .string)
        let sentinel2 = UUID().uuidString
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(sentinel2, forType: .string)
        let sentinel2ChangeCount = NSPasteboard.general.changeCount
        sendCommandCAppleScript()

        let startTime2 = Date()
        var copied2: String?
        while Date().timeIntervalSince(startTime2) < 2.0 {
            try? await Task.sleep(for: .milliseconds(100))
            let currentChangeCount = NSPasteboard.general.changeCount
            if currentChangeCount != sentinel2ChangeCount {
                let current = NSPasteboard.general.string(forType: .string)
                if let current, current != sentinel2 {
                    copied2 = current
                }
                break
            }
        }

        // Restore clipboard
        NSPasteboard.general.clearContents()
        if let previous2 {
            NSPasteboard.general.setString(previous2, forType: .string)
        }

        if let copied2, !copied2.isEmpty {
            Log.app.info("AppleScript track succeeded, length: \(copied2.count, privacy: .public)")
            return copied2
        }

        Log.app.info("all tracks failed, returning empty")
        return ""
    }

    /// Send ⌘C via CGEvent (.cgAnnotatedSessionEventTap).
    private func sendCommandC() async {
        let source = CGEventSource(stateID: .combinedSessionState)
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        else {
            Log.app.warning("sendCommandC failed to create CGEvent")
            return
        }

        keyDown.flags = .maskCommand
        keyUp.flags = .maskCommand

        keyDown.post(tap: .cgAnnotatedSessionEventTap)
        try? await Task.sleep(for: .milliseconds(50))
        keyUp.post(tap: .cgAnnotatedSessionEventTap)

        Log.app.info("⌘C sent via cgAnnotatedSessionEventTap")
    }

    /// Send ⌘C via AppleScript / System Events.
    private func sendCommandCAppleScript() {
        let script = NSAppleScript(source: """
            tell application "System Events"
                keystroke "c" using {command down}
            end tell
        """)
        var errorInfo: NSDictionary?
        script?.executeAndReturnError(&errorInfo)
        if let error = errorInfo {
            Log.app.warning("AppleScript ⌘C failed: \(error)")
        } else {
            Log.app.info("AppleScript ⌘C executed")
        }
    }

    // MARK: - State

    private func handleCurrentState() {
        switch appState.modelState {
        case .termsRequired, .notDownloaded:
            onboardingController?.showIfNeeded()
        case .ready:
            onboardingController?.dismissIfReady()
        default:
            break
        }
    }
}
