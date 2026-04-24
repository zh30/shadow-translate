import AccessibilityKit
import AppKit
import Foundation
import PersistenceKit
import SharedCore

@MainActor
@Observable
public final class TranslationPopupViewModel {
    public enum Status: Equatable, Sendable {
        case idle
        case translating
        case translated
        case emptyInput
        case unsupportedInput
        case failed(String)
    }

    public typealias Translate = (String, Language, Language) async -> AsyncStream<String>
    public typealias CanReplace = () async -> Bool
    public typealias Replace = (String) async throws -> Void
    public typealias SaveHistory = (String, String, Language, Language) async throws -> Void

    public struct Dependencies {
        let translate: Translate
        let canReplace: CanReplace
        let replace: Replace
        let saveHistory: SaveHistory
        let pasteboard: NSPasteboard

        public init(
            translate: @escaping Translate,
            canReplace: @escaping CanReplace,
            replace: @escaping Replace,
            saveHistory: @escaping SaveHistory,
            pasteboard: NSPasteboard = .general
        ) {
            self.translate = translate
            self.canReplace = canReplace
            self.replace = replace
            self.saveHistory = saveHistory
            self.pasteboard = pasteboard
        }

        @MainActor
        public static func production(appState: AppState) -> Dependencies {
            let replacer = AXReplacer()
            let writer = HistoryStore.shared.makeWriter()
            let inference = appState.inference
            return Dependencies(
                translate: { text, source, target in
                    await inference.translate(text: text, source: source, target: target)
                },
                canReplace: {
                    await replacer.canReplaceDirectly()
                },
                replace: { text in
                    try await replacer.replaceSelectedText(text)
                },
                saveHistory: { sourceText, translatedText, source, target in
                    let appName = NSWorkspace.shared.frontmostApplication?.localizedName
                    _ = try await writer.insert(
                        sourceText: sourceText,
                        translatedText: translatedText,
                        sourceLang: source,
                        targetLang: target,
                        sourceApp: appName
                    )
                }
            )
        }

        public static func test(
            translate: @escaping Translate = { _, _, _ in AsyncStream { $0.finish() } },
            canReplace: @escaping CanReplace = { false },
            replace: @escaping Replace = { _ in },
            saveHistory: @escaping SaveHistory = { _, _, _, _ in }
        ) -> Dependencies {
            Dependencies(
                translate: translate,
                canReplace: canReplace,
                replace: replace,
                saveHistory: saveHistory,
                pasteboard: .general
            )
        }
    }

    public var sourceLanguage: Language
    public var targetLanguage: Language
    public var sourceText: String
    public var translatedText = ""
    public var status: Status = .idle
    public var canReplace = false

    private let dependencies: Dependencies
    private var translationTask: Task<Void, Never>?
    private var lastSavedPair: String?

    public init(
        initialText: String = "",
        sourceLanguage: Language = .auto,
        targetLanguage: Language = .zh,
        dependencies: Dependencies
    ) {
        self.sourceText = initialText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.dependencies = dependencies
    }

    public var isTranslating: Bool {
        status == .translating
    }

    public var statusMessage: String? {
        switch status {
        case .idle, .translating, .translated:
            nil
        case .emptyInput:
            "请选择需要翻译的文本"
        case .unsupportedInput:
            "选中文本过短或仅包含标点"
        case .failed(let message):
            message
        }
    }

    public func refreshReplaceAvailability() async {
        canReplace = await dependencies.canReplace()
    }

    public func startTranslation() async {
        translatedText = ""

        let input = normalizedSourceText()
        guard !input.isEmpty else {
            status = .emptyInput
            return
        }
        guard input.contains(where: { $0.isLetter || $0.isNumber }) else {
            status = .unsupportedInput
            return
        }

        status = .translating
        var output = ""

        let stream = await dependencies.translate(input, sourceLanguage, targetLanguage)
        for await chunk in stream {
            if Task.isCancelled { return }
            output += chunk
            translatedText = output
        }

        if output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            status = .failed("翻译失败，请稍后重试")
            return
        }

        translatedText = output
        status = .translated
        await saveHistoryIfNeeded(sourceText: input, translatedText: output)
    }

    public func restartTranslation() {
        translationTask?.cancel()
        translationTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            await self?.startTranslation()
        }
    }

    public func copyTranslation() {
        guard !translatedText.isEmpty else { return }
        dependencies.pasteboard.clearContents()
        dependencies.pasteboard.setString(translatedText, forType: .string)
    }

    public func replaceSelection() async {
        guard !translatedText.isEmpty else { return }
        do {
            try await dependencies.replace(translatedText)
        } catch {
            status = .failed(error.localizedDescription)
        }
    }

    private func normalizedSourceText() -> String {
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.count > 8_000 {
            return String(trimmed.prefix(8_000))
        }
        return trimmed
    }

    private func saveHistoryIfNeeded(sourceText: String, translatedText: String) async {
        let pair = "\(sourceText)\u{1f}\(translatedText)\u{1f}\(sourceLanguage.rawValue)\u{1f}\(targetLanguage.rawValue)"
        guard pair != lastSavedPair else { return }
        do {
            try await dependencies.saveHistory(sourceText, translatedText, sourceLanguage, targetLanguage)
            lastSavedPair = pair
        } catch {
            Log.persistence.error("TranslationPopupViewModel.saveHistoryIfNeeded · \(error.localizedDescription)")
        }
    }
}
