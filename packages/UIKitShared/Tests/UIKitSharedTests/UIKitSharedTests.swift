import Testing
@testable import UIKitShared

@Test func versionIsNonEmpty() {
    #expect(!UIKitShared.version.isEmpty)
}
