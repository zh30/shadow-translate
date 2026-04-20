import Testing
@testable import PersistenceKit

@Test func versionIsNonEmpty() {
    #expect(!PersistenceKit.version.isEmpty)
}
