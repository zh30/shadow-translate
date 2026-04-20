import Testing
@testable import ModelManager

@Test func versionIsNonEmpty() {
    #expect(!ModelManager.version.isEmpty)
}
