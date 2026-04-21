import Foundation
import SwiftData
import SharedCore

@ModelActor
public actor HistoryWriter {
    public func insert(
        sourceText: String,
        translatedText: String,
        sourceLang: Language,
        targetLang: Language,
        sourceApp: String? = nil
    ) throws -> TranslationRecord {
        let record = TranslationRecord(
            sourceText: sourceText,
            translatedText: translatedText,
            sourceLang: sourceLang.rawValue,
            targetLang: targetLang.rawValue,
            sourceApp: sourceApp,
            dayBucket: TranslationRecord.dayBucketString(from: Date())
        )
        modelContext.insert(record)
        try modelContext.save()
        Log.persistence.info("HistoryWriter.insert · saved record \(record.id)")
        return record
    }

    public func toggleFavorite(_ id: UUID) throws {
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else {
            Log.persistence.warning("HistoryWriter.toggleFavorite · record \(id) not found")
            return
        }
        record.isFavorite.toggle()
        try modelContext.save()
    }

    public func addTag(_ tagName: String, to id: UUID) throws {
        let tag = try findOrCreateTag(name: tagName)
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else { return }
        record.tags.append(tag)
        try modelContext.save()
    }

    public func delete(_ id: UUID) throws {
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try modelContext.fetch(descriptor).first else { return }
        modelContext.delete(record)
        try modelContext.save()
    }

    private func findOrCreateTag(name: String) throws -> Tag {
        let descriptor = FetchDescriptor<Tag>(
            predicate: #Predicate { $0.name == name }
        )
        if let existing = try modelContext.fetch(descriptor).first {
            return existing
        }
        let tag = Tag(name: name)
        modelContext.insert(tag)
        return tag
    }
}