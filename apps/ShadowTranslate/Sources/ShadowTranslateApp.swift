import AppKit
import KeyboardShortcuts
import SharedCore
import SwiftUI
import UIKitShared

@main
struct ShadowTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Shadow Translate", systemImage: "character.bubble") {
            MenuBarContent()
                .environment(appDelegate.appState)
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "main") {
            MainWindowView()
                .environment(appDelegate.appState)
                .frame(minWidth: Theme.Size.mainWindowMinWidth, minHeight: Theme.Size.mainWindowMinHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)

        WindowGroup(id: "settings") {
            SettingsView()
                .environment(appDelegate.appState)
                .frame(minWidth: 560, minHeight: 380)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)

        WindowGroup(id: "popup") {
            TranslationPopupView()
                .environment(appDelegate.appState)
                .frame(width: Theme.Size.popupWidth, height: Theme.Size.popupMinHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

private struct MenuBarContent: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().padding(.vertical, 8)
            menuButton(
                title: "翻译选中文本",
                icon: "text.bubble",
                disabled: !appState.modelState.isReady
            ) {
                FloatingPanelController.shared.show {
                    TranslationPopupView()
                }
            }
            menuButton(
                title: "打开历史窗口",
                icon: "clock.arrow.circlepath"
            ) {
                openWindow(id: "main")
            }
            menuButton(
                title: "偏好设置…",
                icon: "gearshape"
            ) {
                openWindow(id: "settings")
            }
            Divider().padding(.vertical, 8)
            menuButton(
                title: "退出",
                icon: "power"
            ) {
                NSApp.terminate(nil)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
        .frame(width: 260)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "character.bubble.fill")
                .font(.title2)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Shadow Translate")
                    .font(.headline)
                Text("v\(SharedCore.version) · \(appState.modelState.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 4)
    }

    private func menuButton(
        title: String,
        icon: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
        }
        .buttonStyle(MenuButtonStyle())
        .disabled(disabled)
    }
}

private struct MenuButtonStyle: ButtonStyle {
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isHovered ? Color.accentColor.opacity(0.15) : Color.clear)
            .foregroundStyle(configuration.isPressed ? Color.accentColor : Color.primary)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onHover { hover in
                withAnimation(.easeInOut(duration: 0.08)) {
                    isHovered = hover
                }
            }
    }
}