import Testing
import Foundation
import SharedCore
@testable import PersistenceKit

@Test func versionIsNonEmpty() {
    #expect(!PersistenceKit.version.isEmpty)
}

@Test func historyExporterWritesStableJSONFields() throws {
    let record = TranslationRecord(
        sourceText: "Hello",
        translatedText: "你好",
        sourceLang: .en,
        targetLang: .zh,
        timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        sourceApp: "Notes",
        isFavorite: true,
        tags: [Tag(name: "work")]
    )

    let data = try HistoryExporter.exportJSON([record])
    let object = try #require(
        JSONSerialization.jsonObject(with: data) as? [[String: Any]]
    ).first

    #expect(object["sourceText"] as? String == "Hello")
    #expect(object["translatedText"] as? String == "你好")
    #expect(object["sourceLang"] as? String == Language.en.rawValue)
    #expect(object["targetLang"] as? String == Language.zh.rawValue)
    #expect(object["sourceApp"] as? String == "Notes")
    #expect(object["isFavorite"] as? Bool == true)
    #expect(object["tags"] as? [String] == ["work"])
}

@Test func historyExporterEscapesCSVValues() throws {
    let record = TranslationRecord(
        sourceText: "Hello, \"world\"",
        translatedText: "你好\n世界",
        sourceLang: .en,
        targetLang: .zh,
        timestamp: Date(timeIntervalSince1970: 1_700_000_000),
        sourceApp: "TextEdit"
    )

    let csv = String(decoding: HistoryExporter.exportCSV([record]), as: UTF8.self)

    #expect(csv.hasPrefix("id,sourceText,translatedText,sourceLang,targetLang,timestamp,sourceApp,isFavorite,tags\n"))
    #expect(csv.contains("\"Hello, \"\"world\"\"\""))
    #expect(csv.contains("\"你好\n世界\""))
}
