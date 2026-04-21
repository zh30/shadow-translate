import Foundation
import SwiftData

@Model
public final class TranslationRecord {
    @Attribute(.unique) public var id: UUID
    public var sourceText: String
    public var translatedText: String
    public var sourceLang: String
    public var targetLang: String
    public var timestamp: Date
    public var sourceApp: String?
    public var isFavorite: Bool
    public var dayBucket: String

    @Relationship(deleteRule: .nullify, inverse: \Tag.records)
    public var tags: [Tag]

    init(
        id: UUID = UUID(),
        sourceText: String,
        translatedText: String,
        sourceLang: String,
        targetLang: String,
        timestamp: Date = Date(),
        sourceApp: String? = nil,
        isFavorite: Bool = false,
        dayBucket: String,
        tags: [Tag] = []
    ) {
        self.id = id
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.timestamp = timestamp
        self.sourceApp = sourceApp
        self.isFavorite = isFavorite
        self.dayBucket = dayBucket
        self.tags = tags
    }
}

@Model
public final class Tag {
    @Attribute(.unique) public var name: String
    public var records: [TranslationRecord] = []

    init(name: String) {
        self.name = name
    }
}

public enum PersistenceSchemaV1: VersionedSchema {
    public static let versionIdentifier = Schema.Version(1, 0, 0)

    public static let models: [any PersistentModel.Type] = [
        TranslationRecord.self, Tag.self
    ]
}

public enum PersistenceMigrationPlan: SchemaMigrationPlan {
    public static let schemas: [VersionedSchema.Type] = [
        PersistenceSchemaV1.self
    ]

    public static let stages: [MigrationStage] = []
}