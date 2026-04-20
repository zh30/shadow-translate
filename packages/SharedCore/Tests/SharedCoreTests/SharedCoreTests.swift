import Testing
@testable import SharedCore

@Test func versionIsNonEmpty() {
    #expect(!SharedCore.version.isEmpty)
}

@Test func languageEnumIncludesAuto() {
    #expect(Language.allCases.contains(.auto))
}
