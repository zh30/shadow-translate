import XCTest
import Foundation
import InferenceKit
import PersistenceKit
import SharedCore
import UIKitShared

final class ShadowTranslateTests: XCTestCase {
    func testDeepLHotkeyStateMachineTriggersOnlyInsideWindow() {
        var machine = DeepLHotkeyStateMachine(window: 0.35)

        XCTAssertFalse(machine.handle(.commandC, at: 1.00))
        XCTAssertTrue(machine.handle(.commandC, at: 1.30))
        XCTAssertFalse(machine.handle(.commandC, at: 2.00))
        XCTAssertFalse(machine.handle(.commandC, at: 2.36))
    }

    func testLanguageNamesAreAvailableForMainUIPickers() {
        XCTAssertFalse(Language.en.localizedName.isEmpty)
        XCTAssertFalse(Language.zh.localizedName.isEmpty)
        XCTAssertFalse(Language.auto.localizedName.isEmpty)
    }

    func testLanguageDetectorRecognizesPrimaryLanguages() {
        XCTAssertEqual(LanguageDetector.detect("This is a short English sentence for detection.", confidenceThreshold: 0.1), .en)
        XCTAssertEqual(LanguageDetector.detect("这是一段用于语言检测的中文文本。", confidenceThreshold: 0.1), .zh)
    }

    func testHistoryExporterCSVEscapesFixedFields() throws {
        let record = TranslationRecord(
            sourceText: "Hello, \"world\"",
            translatedText: "你好\n世界",
            sourceLang: .en,
            targetLang: .zh,
            timestamp: Date(timeIntervalSince1970: 0),
            sourceApp: "UnitTest",
            isFavorite: true
        )

        let csv = String(decoding: HistoryExporter.exportCSV([record]), as: UTF8.self)

        XCTAssertTrue(csv.hasPrefix(HistoryExporter.fields.joined(separator: ",")))
        XCTAssertTrue(csv.contains("\"Hello, \"\"world\"\"\""))
        XCTAssertTrue(csv.contains("\"你好\n世界\""))
        XCTAssertTrue(csv.contains(",UnitTest,true,"))
    }

    @MainActor
    func testPopupViewModelSkipsEmptyInput() async {
        var didTranslate = false
        let viewModel = TranslationPopupViewModel(
            initialText: "   ",
            dependencies: .test(translate: { _, _, _ in
                didTranslate = true
                return AsyncStream { $0.finish() }
            })
        )

        await viewModel.startTranslation()

        XCTAssertFalse(didTranslate)
        XCTAssertEqual(viewModel.status, .emptyInput)
        XCTAssertTrue(viewModel.translatedText.isEmpty)
    }

    @MainActor
    func testPopupViewModelStreamsAndSavesHistory() async throws {
        var saved: (String, String, Language, Language)?
        let viewModel = TranslationPopupViewModel(
            initialText: "Hello",
            sourceLanguage: .en,
            targetLanguage: .zh,
            dependencies: .test(
                translate: { _, _, _ in
                    AsyncStream { continuation in
                        continuation.yield("你")
                        continuation.yield("好")
                        continuation.finish()
                    }
                },
                saveHistory: { source, translated, sourceLang, targetLang in
                    saved = (source, translated, sourceLang, targetLang)
                }
            )
        )

        await viewModel.startTranslation()

        XCTAssertEqual(viewModel.status, .translated)
        XCTAssertEqual(viewModel.translatedText, "你好")
        XCTAssertEqual(saved?.0, "Hello")
        XCTAssertEqual(saved?.1, "你好")
        XCTAssertEqual(saved?.2, .en)
        XCTAssertEqual(saved?.3, .zh)
    }

    @MainActor
    func testPopupViewModelRestartTranslationDoesNotCancelItself() async throws {
        let viewModel = TranslationPopupViewModel(
            initialText: "Hello",
            dependencies: .test(
                translate: { _, _, _ in
                    AsyncStream { continuation in
                        continuation.yield("你好")
                        continuation.finish()
                    }
                }
            )
        )

        viewModel.restartTranslation()
        try await Task.sleep(for: .milliseconds(400))

        XCTAssertEqual(viewModel.status, .translated)
        XCTAssertEqual(viewModel.translatedText, "你好")
    }
}
