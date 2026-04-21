import Foundation
import SwiftData
import SharedCore

extension TranslationRecord {
    public convenience init(
        sourceText: String,
        translatedText: String,
        sourceLang: Language,
        targetLang: Language,
        timestamp: Date = Date(),
        sourceApp: String? = nil,
        isFavorite: Bool = false,
        tags: [Tag] = []
    ) {
        self.init(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLang: sourceLang.rawValue,
            targetLang: targetLang.rawValue,
            timestamp: timestamp,
            sourceApp: sourceApp,
            isFavorite: isFavorite,
            dayBucket: Self.dayBucketString(from: timestamp),
            tags: tags
        )
    }

    public var sourceLanguage: Language {
        Language(rawValue: sourceLang) ?? .en
    }

    public var targetLanguage: Language {
        Language(rawValue: targetLang) ?? .zh
    }

    static func dayBucketString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}