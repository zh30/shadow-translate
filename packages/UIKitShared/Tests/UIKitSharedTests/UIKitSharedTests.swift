import Testing
import SharedCore
@testable import UIKitShared

@Test func versionIsNonEmpty() {
    #expect(!UIKitShared.version.isEmpty)
}

@MainActor
@Test func popupViewModelDoesNotTranslateEmptyText() async {
    var translateCalls = 0
    let viewModel = TranslationPopupViewModel(
        initialText: "   ",
        dependencies: .test(
            translate: { _, _, _ in
                translateCalls += 1
                return AsyncStream { $0.finish() }
            }
        )
    )

    await viewModel.startTranslation()

    #expect(translateCalls == 0)
    #expect(viewModel.status == .emptyInput)
    #expect(viewModel.translatedText.isEmpty)
}

@MainActor
@Test func popupViewModelStreamsTranslationAndSavesHistory() async throws {
    var saved: (String, String, Language, Language)?
    let viewModel = TranslationPopupViewModel(
        initialText: "Hello",
        dependencies: .test(
            translate: { text, source, target in
                #expect(text == "Hello")
                #expect(source == .auto)
                #expect(target == .zh)
                return AsyncStream { continuation in
                    continuation.yield("你")
                    continuation.yield("好")
                    continuation.finish()
                }
            },
            saveHistory: { sourceText, translatedText, source, target in
                saved = (sourceText, translatedText, source, target)
            }
        )
    )

    await viewModel.startTranslation()

    #expect(viewModel.status == .translated)
    #expect(viewModel.translatedText == "你好")
    #expect(saved?.0 == "Hello")
    #expect(saved?.1 == "你好")
    #expect(saved?.2 == .auto)
    #expect(saved?.3 == .zh)
}

@MainActor
@Test func popupViewModelRestartTranslationDoesNotCancelItself() async throws {
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

    #expect(viewModel.status == .translated)
    #expect(viewModel.translatedText == "你好")
}

@Test func deeplHotkeyStateMachineRequiresSecondCommandCWithinWindow() {
    var machine = DeepLHotkeyStateMachine(window: 0.35)

    #expect(machine.handle(.commandC, at: 10.00) == false)
    #expect(machine.handle(.commandC, at: 10.34) == true)
    #expect(machine.handle(.commandC, at: 11.00) == false)
    #expect(machine.handle(.commandC, at: 11.36) == false)
}
