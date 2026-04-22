import AppKit
import SwiftUI

@MainActor
public final class FloatingPanelController {
    public static let shared = FloatingPanelController()

    private var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private weak var appState: AppState?

    private init() {}

    public func configure(appState: AppState) {
        self.appState = appState
    }

    public func show<Content: View>(@ViewBuilder content: () -> Content) {
        let view = content()
        let wrappedView: AnyView
        if let appState {
            wrappedView = AnyView(view.environment(appState))
        } else {
            wrappedView = AnyView(view)
        }

        if let existingPanel = panel {
            let newHosting = NSHostingView(rootView: wrappedView)
            newHosting.autoresizingMask = [.width, .height]
            existingPanel.contentView = newHosting
            self.hostingView = newHosting
            newHosting.layoutSubtreeIfNeeded()
            positionPanel(existingPanel)
            existingPanel.makeKeyAndOrderFront(nil)
            installDismissMonitors()
            return
        }

        let newPanel = NSPanel(
            contentRect: NSRect(
                x: 0, y: 0,
                width: Theme.Size.popupWidth,
                height: Theme.Size.popupMinHeight
            ),
            styleMask: [.nonactivatingPanel, .titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newPanel.isFloatingPanel = true
        newPanel.level = .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        newPanel.isMovableByWindowBackground = true
        newPanel.titlebarAppearsTransparent = true
        newPanel.titleVisibility = .hidden
        newPanel.isReleasedWhenClosed = false
        newPanel.hidesOnDeactivate = false
        newPanel.hasShadow = true
        newPanel.backgroundColor = .clear

        let hosting = NSHostingView(rootView: wrappedView)
        hosting.autoresizingMask = [.width, .height]
        newPanel.contentView = hosting

        self.panel = newPanel
        self.hostingView = hosting

        positionPanel(newPanel)
        newPanel.makeKeyAndOrderFront(nil)
        installDismissMonitors()
    }

    public func hide() {
        removeDismissMonitors()
        panel?.orderOut(nil)
    }

    public var isVisible: Bool {
        panel?.isVisible == true
    }

    // MARK: - Private

    private func positionPanel(_ panel: NSPanel) {
        let mouseLocation = NSEvent.mouseLocation
        let screenFrame = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1920, height: 1080)

        let panelWidth = Theme.Size.popupWidth
        let panelHeight = Theme.Size.popupMinHeight

        var origin = mouseLocation
        origin.x -= panelWidth / 2
        origin.y -= panelHeight + 20

        origin.x = max(screenFrame.minX, min(origin.x, screenFrame.maxX - panelWidth))
        origin.y = max(screenFrame.minY, min(origin.y, screenFrame.maxY - panelHeight))

        panel.setFrameOrigin(origin)
    }

    private func installDismissMonitors() {
        removeDismissMonitors()

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.hide()
                return nil
            }
            return event
        }

        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            if let panel = self?.panel {
                let mouse = NSEvent.mouseLocation
                if !panel.frame.contains(mouse) {
                    self?.hide()
                }
            }
        }
    }

    private func removeDismissMonitors() {
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
            globalMonitor = nil
        }
    }
}