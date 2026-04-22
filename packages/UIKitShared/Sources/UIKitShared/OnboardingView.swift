import ModelManager
import SharedCore
import SwiftUI

public struct OnboardingView: View {
    @Bindable var appState: AppState
    @State private var hasAgreed = false
    @State private var termsText = ""

    public init(appState: AppState) {
        self._appState = .init(appState)
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            content
            Divider()
            footer
        }
        .frame(width: 520)
        .materialBackground()
        .task { termsText = await appState.termsText }
        .onChange(of: appState.modelState.isReady) { _, isReady in
            if isReady {
                dismissWindow()
            }
        }
    }

    private func dismissWindow() {
        NSApp.keyWindow?.close()
    }

    // MARK: - Header

    private var header: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: "character.bubble.fill")
                .font(.largeTitle)
                .foregroundStyle(.tint)
            VStack(alignment: .leading, spacing: 2) {
                Text("Shadow Translate")
                    .font(.title2.bold())
                Text("欢迎使用")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(Theme.Spacing.xl)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch appState.modelState {
        case .termsRequired, .notDownloaded:
            termsStep
        case .downloading(let progress, let speed, let eta):
            downloadStep(progress: progress, speed: speed, eta: eta)
        case .verifying:
            verifyingStep
        case .loading:
            loadingStep
        case .ready:
            completionStep
        case .error(let msg):
            errorStep(message: msg)
        }
    }

    private var termsStep: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("使用条款")
                .font(.headline)

            ScrollView {
                Text(termsText)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 260)
            .padding(Theme.Spacing.md)
            .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.small))

            Toggle(isOn: $hasAgreed) {
                Text("我已阅读并同意以上条款")
                    .font(.subheadline)
            }
        }
        .padding(Theme.Spacing.xl)
    }

    private func downloadStep(progress: Double, speed: String, eta: String?) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            Text("下载模型")
                .font(.headline)

            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: "cpu")
                    .font(.title2)
                    .foregroundStyle(.secondary)
                VStack(alignment: .leading, spacing: 2) {
                    Text("TranslateGemma 4B IT (4-bit)")
                        .font(.subheadline.bold())
                    Text("约 2.18 GB · 来自 HuggingFace")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            ProgressView(value: progress) {
                EmptyView()
            } currentValueLabel: {
                HStack {
                    Text("\(Int(progress * 100))%")
                        .font(.caption.monospacedDigit())
                    if !speed.isEmpty {
                        Text("· \(speed)")
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
            .progressViewStyle(.linear)

            Button("取消下载") {
                Task { await appState.cancelDownload() }
            }
            .buttonStyle(.bordered)
        }
        .padding(Theme.Spacing.xl)
    }

    private var verifyingStep: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
            Text("正在校验模型文件…")
                .font(.headline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    private var loadingStep: some View {
        VStack(spacing: Theme.Spacing.lg) {
            ProgressView()
                .controlSize(.large)
            Text("正在加载模型到内存…")
                .font(.headline)
            Text("首次加载可能需要几秒钟")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    private var completionStep: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.green)
            Text("模型已就绪！")
                .font(.title3.bold())
            Text("选择文本并按 ⌘⇧T 即可翻译")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    private func errorStep(message: String) -> some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundStyle(.orange)
            Text("下载失败")
                .font(.headline)
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Button("重试") {
                Task { await appState.startDownload() }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Theme.Spacing.xxl)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            Spacer()
            if case .termsRequired = appState.modelState {
                Button("同意并继续") {
                    Task {
                        await appState.acceptTerms()
                        await appState.startDownload()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!hasAgreed)
            } else if case .notDownloaded = appState.modelState {
                Button("开始下载") {
                    Task { await appState.startDownload() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(Theme.Spacing.lg)
    }
}