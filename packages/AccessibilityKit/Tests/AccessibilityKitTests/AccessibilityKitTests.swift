import Testing
@testable import AccessibilityKit

@Test func versionIsNonEmpty() {
    #expect(!AccessibilityKit.version.isEmpty)
}
