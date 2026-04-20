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
        }
        .menuBarExtraStyle(.window)

        WindowGroup(id: "main") {
            MainWindowView()
                .frame(minWidth: Theme.Size.mainWindowMinWidth, minHeight: Theme.Size.mainWindowMinHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)

        Settings {
            SettingsView()
        }

        WindowGroup(id: "popup") {
            TranslationPopupView()
                .frame(width: Theme.Size.popupWidth, height: Theme.Size.popupMinHeight)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

private struct MenuBarContent: View {
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "character.bubble.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Shadow Translate")
                        .font(.headline)
                    Text("v\(SharedCore.version) · 就绪")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Divider()
            Button {
                FloatingPanelController.shared.show {
                    TranslationPopupView()
                }
            } label: {
                Label("翻译选中文本", systemImage: "text.bubble")
            }
            .buttonStyle(.borderless)
            Button {
                openWindow(id: "main")
            } label: {
                Label("打开历史窗口", systemImage: "clock.arrow.circlepath")
            }
            .buttonStyle(.borderless)
            Button {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            } label: {
                Label("偏好设置…", systemImage: "gearshape")
            }
            .buttonStyle(.borderless)
            Divider()
            Button {
                NSApp.terminate(nil)
            } label: {
                Label("退出", systemImage: "power")
            }
            .buttonStyle(.borderless)
        }
        .padding(16)
        .frame(width: 260)
    }
}