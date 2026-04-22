import AppKit
import SwiftUI

@MainActor
public final class OnboardingWindowController: NSWindowController {
    private let appState: AppState

    public init(appState: AppState) {
        self.appState = appState

        let hostingView = NSHostingView(rootView: OnboardingView(appState: appState))
        hostingView.setFrameSize(NSSize(width: 520, height: 540))

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 540),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Shadow Translate — 初始设置"
        window.contentView = hostingView
        window.isReleasedWhenClosed = false
        window.center()
        window.level = .floating

        super.init(window: window)
    }

    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    public func showIfNeeded() {
        guard let window, !window.isVisible else { return }
        NSApp.activate(ignoringOtherApps: true)
        showWindow(nil)
        window.makeKeyAndOrderFront(nil)
    }

    public func dismissIfReady() {
        if appState.modelState.isReady {
            close()
        }
    }
}