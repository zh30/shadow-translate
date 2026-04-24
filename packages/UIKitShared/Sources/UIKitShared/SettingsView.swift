@preconcurrency import ApplicationServices
import AppKit
import KeyboardShortcuts
import PersistenceKit
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
        .frame(width: 720, height: 560)
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    @AppStorage("defaultSourceLanguage") private var defaultSourceLanguage = Language.auto.rawValue
    @AppStorage("defaultTargetLanguage") private var defaultTargetLanguage = Language.zh.rawValue
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("uiLanguage") private var uiLanguage = "zh-Hans"

    var body: some View {
        SettingsPage(
            title: "通用",
            subtitle: "配置默认语言、启动行为和界面语言。",
            systemImage: "slider.horizontal.3",
            accent: .blue
        ) {
            SettingsSection("语言偏好", systemImage: "character.bubble") {
                SettingsRow(
                    title: "源语言",
                    detail: "选择文本后默认使用的识别方式。"
                ) {
                    Picker("源语言", selection: $defaultSourceLanguage) {
                        ForEach(Language.allCases, id: \.rawValue) { lang in
                            Text(lang.localizedName).tag(lang.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }

                SettingsDivider()

                SettingsRow(
                    title: "目标语言",
                    detail: "弹窗和历史重新翻译默认使用该目标语言。"
                ) {
                    Picker("目标语言", selection: $defaultTargetLanguage) {
                        ForEach(Language.allCases.filter(\.isBindable), id: \.rawValue) { lang in
                            Text(lang.localizedName).tag(lang.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 190)
                }
            }

            SettingsSection("应用行为", systemImage: "macwindow") {
                SettingsRow(
                    title: "登录时自动启动",
                    detail: "适合把 Shadow Translate 作为常驻菜单栏工具使用。"
                ) {
                    Toggle("", isOn: $launchAtLogin)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }

                SettingsDivider()

                SettingsRow(
                    title: "界面语言",
                    detail: uiLanguage == "zh-Hans" ? "当前使用简体中文界面。" : "Current interface language is English."
                ) {
                    Picker("界面语言", selection: $uiLanguage) {
                        Text("简体中文").tag("zh-Hans")
                        Text("English").tag("en")
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 190)
                }
            }
        }
    }
}

// MARK: - Shortcut

private struct ShortcutSettingsView: View {
    @AppStorage("hotkeyMode") private var hotkeyMode = HotkeyMode.simple.rawValue
    @AppStorage("deepLHotkeyStatus") private var deepLHotkeyStatus = DeepLHotkeyMonitorStatus.inactive.rawValue

    var body: some View {
        SettingsPage(
            title: "快捷键",
            subtitle: "选择触发方式，并检查 DeepL 风格双击复制监听状态。",
            systemImage: "keyboard",
            accent: .indigo
        ) {
            SettingsSection("触发方式", systemImage: "bolt") {
                SettingsRow(
                    title: "快捷键模式",
                    detail: modeDescription
                ) {
                    Picker("快捷键模式", selection: $hotkeyMode) {
                        Text("⌘⇧T").tag(HotkeyMode.simple.rawValue)
                        Text("⌘C+C").tag(HotkeyMode.deepL.rawValue)
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                SettingsDivider()

                if hotkeyMode == HotkeyMode.simple.rawValue {
                    SettingsRow(
                        title: "弹窗快捷键",
                        detail: "释放快捷键后会读取当前选中文本并打开翻译弹窗。"
                    ) {
                        KeyboardShortcuts.Recorder("", name: .translatePopup)
                            .labelsHidden()
                            .frame(width: 210)
                    }
                } else {
                    SettingsRow(
                        title: "监听状态",
                        detail: "监听不可用时仍会保留 ⌘⇧T 作为回退。"
                    ) {
                        StatusBadge(
                            monitorStatus.label,
                            systemImage: monitorStatus.systemImage,
                            tint: monitorStatus.tint
                        )
                    }
                }
            }

            if hotkeyMode == HotkeyMode.deepL.rawValue {
                SettingsSection("权限", systemImage: "lock") {
                    SettingsCallout(
                        title: "DeepL 模式需要辅助功能和输入监听权限",
                        message: "macOS 需要这些权限才能检测 350ms 内的第二次 Command-C。",
                        systemImage: "lock.trianglebadge.exclamationmark",
                        tint: .orange
                    )

                    SettingsDivider()

                    HStack(spacing: Theme.Spacing.md) {
                        SettingsActionButton("辅助功能设置", systemImage: "hand.raised") {
                            openPrivacyPane("Privacy_Accessibility")
                        }

                        SettingsActionButton("输入监听设置", systemImage: "keyboard.badge.eye") {
                            openPrivacyPane("Privacy_ListenEvent")
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var modeDescription: String {
        if hotkeyMode == HotkeyMode.deepL.rawValue {
            return "复制一次保留系统行为，350ms 内第二次 ⌘C 打开翻译。"
        }
        return "稳定默认模式，使用可自定义的单一快捷键。"
    }

    private var monitorStatus: DeepLHotkeyMonitorStatus {
        DeepLHotkeyMonitorStatus(rawValue: deepLHotkeyStatus) ?? .inactive
    }

    private func openPrivacyPane(_ anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }
}

private extension DeepLHotkeyMonitorStatus {
    var systemImage: String {
        switch self {
        case .active: "checkmark.circle.fill"
        case .permissionRequired: "lock.trianglebadge.exclamationmark"
        case .fallback: "exclamationmark.triangle.fill"
        case .inactive: "pause.circle"
        }
    }

    var tint: Color {
        switch self {
        case .active: .green
        case .permissionRequired, .fallback: .orange
        case .inactive: .secondary
        }
    }
}

// MARK: - Model

private struct ModelSettingsView: View {
    @Environment(AppState.self) private var appState
    @AppStorage("temperature") private var temperature = 0.2
    @AppStorage("topP") private var topP = 0.95
    @AppStorage("maxTokens") private var maxTokens = 1024
    @AppStorage("lowMemoryMode") private var lowMemoryMode = false

    var body: some View {
        SettingsPage(
            title: "模型",
            subtitle: "管理本地 TranslateGemma 模型和推理参数。",
            systemImage: "cpu",
            accent: statusColor
        ) {
            SettingsSection("模型状态", systemImage: "externaldrive") {
                HStack(alignment: .center, spacing: Theme.Spacing.lg) {
                    ModelIcon(color: statusColor)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("TranslateGemma 4B IT")
                            .font(.headline)
                        Text("4-bit 量化 · 约 2.18 GB · 本地离线推理")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    StatusBadge(
                        appState.modelState.label,
                        systemImage: appState.modelState.systemImage,
                        tint: statusColor
                    )
                }

                if case .downloading(let progress, let speed, let eta) = appState.modelState {
                    SettingsDivider()
                    DownloadProgressView(progress: progress, speed: speed, eta: eta)
                }

                SettingsDivider()

                SettingsRow(
                    title: "存储位置",
                    detail: "~/Library/Application Support/dev.shadow.translate/Models/"
                ) {
                    SettingsActionButton("打开目录", systemImage: "folder") {
                        Task {
                            let url = await appState.localModelDirectory()
                            await MainActor.run {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    }
                }

                SettingsDivider()

                HStack(spacing: Theme.Spacing.md) {
                    SettingsActionButton("检查状态", systemImage: "arrow.clockwise") {
                        Task { await appState.checkModelState() }
                    }

                    modelActionButtons

                    Spacer()
                }
            }

            SettingsSection("推理参数", systemImage: "dial.medium") {
                ParameterRow(
                    title: "Temperature",
                    detail: "数值越高，译文越发散；当前默认偏保守。",
                    value: $temperature,
                    range: 0.0...1.0,
                    step: 0.05
                )

                SettingsDivider()

                ParameterRow(
                    title: "Top-p",
                    detail: "控制候选词采样范围，较高值保留更多可能性。",
                    value: $topP,
                    range: 0.1...1.0,
                    step: 0.05
                )

                SettingsDivider()

                SettingsRow(
                    title: "Max tokens",
                    detail: lowMemoryMode ? "低内存模式会把实际输出上限收紧到 1024。" : "控制单次翻译的最长输出。"
                ) {
                    Stepper("\(maxTokens)", value: $maxTokens, in: 128...4096, step: 128)
                        .monospacedDigit()
                        .frame(width: 118)
                }

                SettingsDivider()

                SettingsRow(
                    title: "低内存模式",
                    detail: "减少 GPU 缓存和空闲驻留时间，适合内存紧张的机器。"
                ) {
                    Toggle("", isOn: $lowMemoryMode)
                        .labelsHidden()
                        .toggleStyle(.switch)
                }
            }
        }
    }

    @ViewBuilder
    private var modelActionButtons: some View {
        switch appState.modelState {
        case .notDownloaded, .termsRequired:
            SettingsActionButton("下载模型", systemImage: "arrow.down.circle", prominence: .primary) {
                Task { await appState.startDownload() }
            }
        case .downloading:
            SettingsActionButton("取消下载", systemImage: "xmark.circle") {
                Task { await appState.cancelDownload() }
            }
        case .ready:
            SettingsActionButton("重新下载", systemImage: "arrow.down.circle") {
                Task { await appState.redownloadModel() }
            }

            SettingsActionButton("删除模型", systemImage: "trash", prominence: .destructive) {
                Task { await appState.deleteModel() }
            }
        case .error:
            SettingsActionButton("重试下载", systemImage: "arrow.down.circle", prominence: .primary) {
                Task { await appState.startDownload() }
            }
        default:
            EmptyView()
        }
    }

    private var statusColor: Color {
        switch appState.modelState {
        case .ready: .green
        case .error: .red
        case .downloading, .loading, .verifying: .blue
        case .termsRequired: .orange
        default: .secondary
        }
    }
}

// MARK: - Privacy

private struct PrivacySettingsView: View {
    @State private var axTrusted = false
    @State private var statusMessage: String?

    var body: some View {
        SettingsPage(
            title: "隐私",
            subtitle: "检查系统权限，并管理本地保存的翻译历史。",
            systemImage: "hand.raised",
            accent: axTrusted ? .green : .orange
        ) {
            SettingsSection("辅助功能权限", systemImage: "person.crop.circle.badge.checkmark") {
                HStack(spacing: Theme.Spacing.lg) {
                    PermissionMeter(isTrusted: axTrusted)

                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text(axTrusted ? "辅助功能权限已授予" : "辅助功能权限未授予")
                            .font(.headline)
                        Text("需要该权限读取选中文本，并在可编辑区域替换为译文。")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    SettingsActionButton("系统设置", systemImage: "gearshape") {
                        openPrivacyPane("Privacy_Accessibility")
                    }
                }
            }

            SettingsSection("历史记录", systemImage: "clock.arrow.circlepath") {
                SettingsCallout(
                    title: "历史记录仅保存在本机",
                    message: "清除后无法恢复。导出 JSON/CSV 请在历史窗口中完成。",
                    systemImage: "externaldrive.badge.checkmark",
                    tint: .blue
                )

                SettingsDivider()

                HStack(spacing: Theme.Spacing.md) {
                    SettingsActionButton("清除所有翻译历史", systemImage: "trash", prominence: .destructive) {
                        clearHistory()
                    }

                    if let statusMessage {
                        StatusBadge(statusMessage, systemImage: "checkmark.circle", tint: .secondary)
                    }

                    Spacer()
                }
            }
        }
        .onAppear { checkAXTrust() }
    }

    private func checkAXTrust() {
        axTrusted = AXIsProcessTrusted()
    }

    private func openPrivacyPane(_ anchor: String) {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(anchor)") else { return }
        NSWorkspace.shared.open(url)
    }

    private func clearHistory() {
        Task {
            do {
                try await HistoryStore.shared.makeWriter().clearAll()
                statusMessage = "历史记录已清除"
            } catch {
                statusMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Shared Settings Components

private struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                SettingsHeader(
                    title: title,
                    subtitle: subtitle,
                    systemImage: systemImage,
                    accent: accent
                )

                content
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: 660, alignment: .topLeading)
        }
        .scrollIndicators(.hidden)
        .background(.regularMaterial)
    }
}

private struct SettingsHeader: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let accent: Color

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 46, height: 46)
                .background(accent.opacity(0.14), in: RoundedRectangle(cornerRadius: SettingsMetrics.corner))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title2.weight(.semibold))
                Text(subtitle)
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.bottom, Theme.Spacing.xs)
    }
}

private struct SettingsSection<Content: View>: View {
    let title: String
    let systemImage: String
    @ViewBuilder var content: Content

    init(_ title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 0) {
                content
            }
            .padding(Theme.Spacing.lg)
            .background(.background.opacity(0.58), in: RoundedRectangle(cornerRadius: SettingsMetrics.corner))
            .overlay {
                RoundedRectangle(cornerRadius: SettingsMetrics.corner)
                    .stroke(.separator.opacity(0.55), lineWidth: 1)
            }
        }
    }
}

private struct SettingsRow<Control: View>: View {
    let title: String
    let detail: String
    @ViewBuilder var control: Control

    var body: some View {
        HStack(alignment: .center, spacing: Theme.Spacing.lg) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: Theme.Spacing.lg)

            control
        }
        .frame(minHeight: 44)
        .accessibilityElement(children: .combine)
    }
}

private struct SettingsDivider: View {
    var body: some View {
        Divider()
            .padding(.vertical, Theme.Spacing.md)
    }
}

private struct SettingsCallout: View {
    let title: String
    let message: String
    let systemImage: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.md) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(tint)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.subheadline.weight(.medium))
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.md)
        .background(tint.opacity(0.10), in: RoundedRectangle(cornerRadius: SettingsMetrics.corner))
        .overlay {
            RoundedRectangle(cornerRadius: SettingsMetrics.corner)
                .stroke(tint.opacity(0.24), lineWidth: 1)
        }
    }
}

private struct SettingsActionButton: View {
    enum Prominence {
        case normal
        case primary
        case destructive
    }

    let title: String
    let systemImage: String
    let prominence: Prominence
    let action: () -> Void

    init(
        _ title: String,
        systemImage: String,
        prominence: Prominence = .normal,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.prominence = prominence
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
                .frame(minHeight: 28)
        }
        .buttonStyle(.bordered)
        .controlSize(.regular)
        .tint(tint)
    }

    private var tint: Color? {
        switch prominence {
        case .normal: nil
        case .primary: .accentColor
        case .destructive: .red
        }
    }
}

private struct StatusBadge: View {
    let text: String
    let systemImage: String
    let tint: Color

    init(_ text: String, systemImage: String, tint: Color) {
        self.text = text
        self.systemImage = systemImage
        self.tint = tint
    }

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.medium))
            .foregroundStyle(tint)
            .lineLimit(1)
            .padding(.horizontal, Theme.Spacing.sm)
            .padding(.vertical, 5)
            .background(tint.opacity(0.12), in: Capsule())
            .accessibilityLabel(text)
    }
}

private struct ModelIcon: View {
    let color: Color

    var body: some View {
        Image(systemName: "cpu.fill")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(color)
            .frame(width: 52, height: 52)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: SettingsMetrics.corner))
            .overlay {
                RoundedRectangle(cornerRadius: SettingsMetrics.corner)
                    .stroke(color.opacity(0.22), lineWidth: 1)
            }
    }
}

private struct DownloadProgressView: View {
    let progress: Double
    let speed: String
    let eta: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            ProgressView(value: progress)
                .progressViewStyle(.linear)

            HStack {
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit())
                if !speed.isEmpty {
                    Text(speed)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let eta {
                    Text("剩余 \(eta)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct ParameterRow: View {
    let title: String
    let detail: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double

    var body: some View {
        SettingsRow(title: title, detail: detail) {
            HStack(spacing: Theme.Spacing.md) {
                Slider(value: $value, in: range, step: step)
                    .frame(width: 190)
                Text(value, format: .number.precision(.fractionLength(2)))
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 36, alignment: .trailing)
            }
        }
    }
}

private struct PermissionMeter: View {
    let isTrusted: Bool

    var body: some View {
        ZStack {
            Circle()
                .stroke((isTrusted ? Color.green : Color.orange).opacity(0.18), lineWidth: 8)
            Circle()
                .trim(from: 0, to: isTrusted ? 1 : 0.62)
                .stroke(
                    isTrusted ? Color.green : Color.orange,
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Image(systemName: isTrusted ? "checkmark" : "exclamationmark")
                .font(.headline.weight(.bold))
                .foregroundStyle(isTrusted ? .green : .orange)
        }
        .frame(width: 54, height: 54)
        .accessibilityLabel(isTrusted ? "辅助功能权限已授予" : "辅助功能权限未授予")
    }
}

private enum SettingsMetrics {
    static let corner: CGFloat = 8
}

// MARK: - KeyboardShortcuts Names

extension KeyboardShortcuts.Name {
    public static let translatePopup = KeyboardShortcuts.Name("translatePopup")
}

// MARK: - Language Helpers

private extension Language {
    var isBindable: Bool { self != .auto }
}
