import SharedCore
import SwiftUI

public struct TranslationPopupView: View {
    @State private var sourceLanguage: Language = .auto
    @State private var targetLanguage: Language = .zh
    @State private var sourceText = ""
    @State private var translatedText = ""
    @State private var isTranslating = false
    @State private var canReplace = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            languageBar
            Divider()
            sourceArea
            Divider()
            resultArea
            Divider()
            actionBar
        }
        .frame(width: Theme.Size.popupWidth - 32)
        .padding(Theme.Spacing.lg)
        .materialBackground()
    }

    // MARK: - Language Bar

    private var languageBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            languagePicker(selection: $sourceLanguage, isSource: true)
            swapButton
            languagePicker(selection: $targetLanguage, isSource: false)
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
                if sourceLanguage != .auto {
                    let temp = sourceLanguage
                    sourceLanguage = targetLanguage
                    targetLanguage = temp
                }
            }
        } label: {
            Image(systemName: "arrow.left.arrow.right")
                .font(.body)
        }
        .buttonStyle(.borderless)
        .disabled(sourceLanguage == .auto)
    }

    // MARK: - Source Area

    private var sourceArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("原文")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $sourceText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 60, maxHeight: 120)
                .padding(Theme.Spacing.sm)
                .background(.fill.tertiary, in: RoundedRectangle(cornerRadius: Theme.CornerRadius.small))
        }
        .padding(.vertical, Theme.Spacing.md)
    }

    // MARK: - Result Area

    private var resultArea: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("译文")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                if isTranslating {
                    ProgressView()
                        .controlSize(.small)
                }
            }

            ScrollView {
                Text(translatedText.isEmpty ? "翻译结果将在这里显示" : translatedText)
                    .font(.body)
                    .foregroundStyle(translatedText.isEmpty ? .tertiary : .primary)
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
                copyTranslation()
            } label: {
                Label("复制", systemImage: "doc.on.doc")
            }
            .buttonStyle(.bordered)
            .disabled(translatedText.isEmpty)

            if canReplace {
                Button {
                    replaceSelection()
                } label: {
                    Label("替换", systemImage: "arrow.left.and.right.text.vertical")
                }
                .buttonStyle(.borderedProminent)
                .disabled(translatedText.isEmpty)
            }

            Spacer()
        }
        .padding(.top, Theme.Spacing.sm)
    }

    // MARK: - Actions

    private func copyTranslation() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(translatedText, forType: .string)
    }

    private func replaceSelection() {
        // Stage 6: Wire up AccessibilityKit AXReplacer
    }
}