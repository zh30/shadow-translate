import Foundation
import SwiftData
import SharedCore

public final class HistoryStore: @unchecked Sendable {
    public static let shared = HistoryStore()

    public let modelContainer: ModelContainer

    private init() {
        do {
            modelContainer = try ModelContainer(
                for: TranslationRecord.self, Tag.self,
                migrationPlan: PersistenceMigrationPlan.self
            )
        } catch {
            fatalError("HistoryStore: failed to create ModelContainer — \(error)")
        }
    }

    public func makeWriter() -> HistoryWriter {
        HistoryWriter(modelContainer: modelContainer)
    }

    // MARK: - Queries

    public func fetchAll(
        limit: Int = 100,
        offset: Int = 0
    ) throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<TranslationRecord>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        descriptor.fetchOffset = offset
        return try context.fetch(descriptor)
    }

    public func fetchFavorites() throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.isFavorite == true },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func fetchByDayBucket(_ bucket: String) throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.dayBucket == bucket },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func searchHistory(_ query: String, limit: Int = 50) throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        let q = query.lowercased()
        var descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate {
                $0.sourceText.localizedStandardContains(q) ||
                $0.translatedText.localizedStandardContains(q)
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return try context.fetch(descriptor)
    }

    public func fetchRecent(days: Int = 7) throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let descriptor = FetchDescriptor<TranslationRecord>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    public func count() throws -> Int {
        let context = ModelContext(modelContainer)
        return try context.fetchCount(FetchDescriptor<TranslationRecord>())
    }
}