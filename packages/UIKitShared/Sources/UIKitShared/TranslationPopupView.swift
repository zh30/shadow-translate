import SharedCore
import SwiftUI

public struct TranslationPopupView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.openWindow) private var openWindow
    @State private var viewModel: TranslationPopupViewModel

    public init(initialText: String = "") {
        self._viewModel = State(
            wrappedValue: TranslationPopupViewModel(
                initialText: initialText,
                dependencies: .test()
            )
        )
    }

    public var body: some View {
        Group {
            if appState.modelState.isReady {
                translationContent
            } else {
                modelNotReadyView
            }
        }
        .frame(width: Theme.Size.popupWidth - 32)
        .padding(Theme.Spacing.lg)
        .materialBackground()
        .task(id: appState.modelState.isReady) {
            guard appState.modelState.isReady else { return }
            viewModel = TranslationPopupViewModel(
                initialText: viewModel.sourceText,
                sourceLanguage: viewModel.sourceLanguage,
                targetLanguage: viewModel.targetLanguage,
                dependencies: .production(appState: appState)
            )
            await viewModel.refreshReplaceAvailability()
            await viewModel.startTranslation()
        }
        .onChange(of: viewModel.sourceLanguage) { _, _ in
            viewModel.restartTranslation()
        }
        .onChange(of: viewModel.targetLanguage) { _, _ in
            viewModel.restartTranslation()
        }
        .onChange(of: viewModel.sourceText) { _, _ in
            viewModel.restartTranslation()
        }
    }

    // MARK: - Not Ready

    private var modelNotReadyView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: appState.modelState.systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(appState.modelState.label)
                .font(.headline)
            switch appState.modelState {
            case .notDownloaded:
                Text("需要先下载本地翻译模型")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("下载模型") {
                        Task { await appState.startDownload() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("打开偏好设置…") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                    }
                    .buttonStyle(.bordered)
                }
            case .termsRequired:
                Text("请先同意模型使用条款，再下载模型")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("打开偏好设置…") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "settings")
                }
                .buttonStyle(.bordered)
            case .error:
                HStack {
                    Button("重试下载") {
                        Task { await appState.startDownload() }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("打开偏好设置…") {
                        NSApp.activate(ignoringOtherApps: true)
                        openWindow(id: "settings")
                    }
                    .buttonStyle(.bordered)
                }
            default:
                ProgressView()
                    .controlSize(.small)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Theme.Size.popupMinHeight - 32)
    }

    // MARK: - Translation Content

    private var translationContent: some View {
        VStack(spacing: 0) {
            languageBar
            Divider()
            sourceArea
            Divider()
            resultArea
            Divider()
            actionBar
        }
    }

    // MARK: - Language Bar

    private var languageBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            languagePicker(selection: sourceLanguageBinding, isSource: true)
            swapButton
            languagePicker(selection: targetLanguageBinding, isSource: false)
        }
        .padding(.bottom, Theme.Spacing.md)
    }

    private func languagePicker(selection: Binding<Language>, isSource: Bool) -> some View {
        Picker(isSource ? "Source" : "Target", selection: selection) {
            ForEach(Language.allCases, id: \.self) { lang in
                Text(lang.localizedName).tag(lang)
            }
        }
        .labelsHidden()
        .pickerStyle(.menu)
    }

    private var swapButton: some View {
        Button {
            withAnimation(Theme.animation) {
                if viewModel.sourceLanguage != .auto {
                    let temp = viewModel.sourceLanguage
                    viewModel.sourceLanguage = viewModel.targetLanguage
                    viewModel.targetLanguage = temp
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.body)
        }
        .buttonStyle(.borderless)
        .disabled(viewModel.sourceLanguage == .auto)
    }

    // MARK: - Source Area

    private var sourceArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("原文")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: sourceTextBinding)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 120)
                .padding(Theme.Spacing.sm)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
                .onSubmit {
                    viewModel.restartTranslation()
                }
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    private var sourceLanguageBinding: Binding<Language> {
        Binding {
            viewModel.sourceLanguage
        } set: { value in
            viewModel.sourceLanguage = value
        }
    }

    private var targetLanguageBinding: Binding<Language> {
        Binding {
            viewModel.targetLanguage
        } set: { value in
            viewModel.targetLanguage = value
        }
    }

    private var sourceTextBinding: Binding<String> {
        Binding {
            viewModel.sourceText
        } set: { value in
            viewModel.sourceText = value
        }
    }

    // MARK: - Result Area

    private var resultArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("译文")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if viewModel.isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ScrollView {
                translatedTextView
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(minHeight: 80, maxHeight: 240)
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            Button {
                viewModel.copyTranslation()
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .disabled(viewModel.translatedText.isEmpty)

            if viewModel.canReplace {
                Button {
                    Task { await viewModel.replaceSelection() }
                } label: {
                    Label("替换", systemImage: "arrow.left.and.right.text.vertical")
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.translatedText.isEmpty)
            }

            Spacer()
        }
        .padding(.top, Theme.Spacing.sm)
    }

    @ViewBuilder
    private var translatedTextView: some View {
        if let message = viewModel.statusMessage {
            Text(message)
                .foregroundStyle(.secondary)
        } else if viewModel.translatedText.isEmpty {
            Text("翻译结果将在这里显示")
                .foregroundStyle(.tertiary)
        } else {
            if let attributed = try? AttributedString(markdown: viewModel.translatedText) {
                Text(attributed)
                    .foregroundStyle(.primary)
            } else {
                Text(viewModel.translatedText)
                    .foregroundStyle(.primary)
            }
        }
    }
}
