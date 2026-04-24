import Foundation

public enum HistoryExporter {
    public static let fields = [
        "id",
        "sourceText",
        "translatedText",
        "sourceLang",
        "targetLang",
        "timestamp",
        "sourceApp",
        "isFavorite",
        "tags",
    ]

    public static func exportJSON(_ records: [TranslationRecord]) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(records.map(ExportRecord.init(record:)))
    }

    public static func exportCSV(_ records: [TranslationRecord]) -> Data {
        var rows = [fields.joined(separator: ",")]
        rows.append(contentsOf: records.map { record in
            let export = ExportRecord(record: record)
            return [
                export.id.uuidString,
                export.sourceText,
                export.translatedText,
                export.sourceLang,
                export.targetLang,
                ISO8601DateFormatter().string(from: export.timestamp),
                export.sourceApp ?? "",
                export.isFavorite ? "true" : "false",
                export.tags.joined(separator: "|"),
            ]
            .map(escapeCSV)
            .joined(separator: ",")
        })
        return Data((rows.joined(separator: "\n") + "\n").utf8)
    }

    private static func escapeCSV(_ value: String) -> String {
        let needsQuotes = value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r")
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return needsQuotes ? "\"\(escaped)\"" : escaped
    }
}

private struct ExportRecord: Codable {
    let id: UUID
    let sourceText: String
    let translatedText: String
    let sourceLang: String
    let targetLang: String
    let timestamp: Date
    let sourceApp: String?
    let isFavorite: Bool
    let tags: [String]

    init(record: TranslationRecord) {
        id = record.id
        sourceText = record.sourceText
        translatedText = record.translatedText
        sourceLang = record.sourceLang
        targetLang = record.targetLang
        timestamp = record.timestamp
        sourceApp = record.sourceApp
        isFavorite = record.isFavorite
        tags = record.tags.map(\.name).sorted()
    }
}
