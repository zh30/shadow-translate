import KeyboardShortcuts
import SharedCore
import SwiftUI

public struct SettingsView: View {
    public init() {}

    public var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("通用", systemImage: "gearshape") }

            ShortcutSettingsView()
                .tabItem { Label("快捷键", systemImage: "keyboard") }

            ModelSettingsView()
                .tabItem { Label("模型", systemImage: "cpu") }

            PrivacySettingsView()
                .tabItem { Label("隐私", systemImage: "hand.raised") }
        }
        .frame(width: 520, height: 420)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = Language.auto.rawValue
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = Language.zh.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin = false

    var body: some View {
        Form {
            Picker("默认源语言", selection: $defaultSourceLanguage) {
                ForEach(Language.allCases, id: \.rawValue) { lang in
                    Text(lang.localizedName).tag(lang.rawValue)
                }
            }

            Picker("默认目标语言", selection: $defaultTargetLanguage) {
                ForEach(Language.allCases.filter(\.isBindable), id: \.rawValue) { lang in
                    Text(lang.localizedName).tag(lang.rawValue)
                }
            }

            Toggle("登录时自动启动", isOn: $launchAtLogin)
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Shortcut

private struct ShortcutSettingsView: View {
    @AppStorage("hotkeyMode") private var hotkeyMode = "simple"

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("快捷键模式")
                .font(.headline)

            Picker("模式", selection: $hotkeyMode) {
                Text("简单模式（⌘⇧T）").tag("simple")
                Text("DeepL 模式（⌘+C+C）").tag("deepL")
            }
            .pickerStyle(.radioGroup)

            Text("简单模式使用 ⌘⇧T 触发翻译弹窗。\nDeepL 模式需要辅助功能权限，双击 ⌘C 触发。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            if hotkeyMode == "simple" {
                KeyboardShortcuts.Recorder("翻译快捷键", name: .translatePopup)
                    .padding(.top, Theme.Spacing.sm)
            }

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

// MARK: - Model

private struct ModelSettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "cpu")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TranslateGemma 4B IT")
                        .font(.headline)
                    Text("4-bit 量化 · 约 2.18 GB")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            HStack {
                Text("模型状态")
                Spacer()
                Label(appState.modelState.label, systemImage: appState.modelState.systemImage)
                    .foregroundStyle(statusColor)
            }

            if case .downloading(let progress, _, _) = appState.modelState {
                ProgressView(value: progress)
                    .progressViewStyle(.linear)
            }

            HStack {
                Text("存储位置")
                Spacer()
                Text("~/Library/Application Support/dev.shadow.translate/Models/")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: Theme.Spacing.md) {
                switch appState.modelState {
                case .notDownloaded, .termsRequired:
                    Button("下载模型") {
                        Task { await appState.startDownload() }
                    }
                    .buttonStyle(.borderedProminent)
                case .downloading:
                    Button("取消下载") {
                        Task { await appState.cancelDownload() }
                    }
                    .buttonStyle(.bordered)
                case .ready:
                    Button("删除模型") {
                        Task { await appState.deleteModel() }
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                case .error:
                    Button("重试下载") {
                        Task { await appState.startDownload() }
                    }
                    .buttonStyle(.borderedProminent)
                default:
                    EmptyView()
                }
            }

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var statusColor: Color {
        switch appState.modelState {
        case .ready: .green
        case .error: .red
        case .downloading, .loading, .verifying: .blue
        default: .secondary
        }
    }
}

// MARK: - Privacy

private struct PrivacySettingsView: View {
    @State private var axTrusted = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("辅助功能")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                Circle()
                    .fill(axTrusted ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)
                Text(axTrusted ? "辅助功能权限已授予" : "辅助功能权限未授予")
                    .font(.subheadline)

                Spacer()

                Button("打开系统设置…") {
                    let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                    NSWorkspace.shared.open(url)
                }
                .buttonStyle(.bordered)
            }

            Text("Shadow Translate 需要辅助功能权限来读取选中文本和替换翻译结果。")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Text("历史记录")
                .font(.headline)

            Button("清除所有翻译历史", role: .destructive) {
                // Stage 5: Wire up PersistenceKit clear
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear { checkAXTrust() }
    }

    private func checkAXTrust() {
        axTrusted = AXIsProcessTrusted()
    }
}

// MARK: - KeyboardShortcuts Names

extension KeyboardShortcuts.Name {
    public static let translatePopup = KeyboardShortcuts.Name("translatePopup")
}

// MARK: - Language Helpers

private extension Language {
    var isBindable: Bool { self != .auto }
}