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
        offset: Int = 0,
        filters: HistoryFilters = .init()
    ) throws -> [TranslationRecord] {
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<TranslationRecord>(
            predicate: filters.predicate,
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

    public func clearAll() throws {
        let context = ModelContext(modelContainer)
        try context.delete(model: TranslationRecord.self)
        try context.delete(model: Tag.self)
        try context.save()
    }

    public func exportJSON(filters: HistoryFilters = .init()) throws -> Data {
        try HistoryExporter.exportJSON(fetchAll(limit: 10_000, filters: filters))
    }

    public func exportCSV(filters: HistoryFilters = .init()) throws -> Data {
        try HistoryExporter.exportCSV(fetchAll(limit: 10_000, filters: filters))
    }

    public func sourceApps(limit: Int = 500) throws -> [String] {
        try fetchAll(limit: limit)
            .compactMap { $0.sourceApp?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .reduce(into: Set<String>()) { $0.insert($1) }
            .sorted()
    }
}

public struct HistoryFilters: Sendable, Equatable {
    public var query: String
    public var sourceLang: Language?
    public var targetLang: Language?
    public var sourceApp: String?
    public var startDate: Date?
    public var endDate: Date?
    public var favoritesOnly: Bool

    public init(
        query: String = "",
        sourceLang: Language? = nil,
        targetLang: Language? = nil,
        sourceApp: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        favoritesOnly: Bool = false
    ) {
        self.query = query
        self.sourceLang = sourceLang
        self.targetLang = targetLang
        self.sourceApp = sourceApp
        self.startDate = startDate
        self.endDate = endDate
        self.favoritesOnly = favoritesOnly
    }

    var predicate: Predicate<TranslationRecord>? {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let sourceLang = sourceLang?.rawValue
        let targetLang = targetLang?.rawValue
        let sourceApp = sourceApp
        let startDate = startDate
        let endDate = endDate
        let favoritesOnly = favoritesOnly

        guard !query.isEmpty || sourceLang != nil || targetLang != nil || sourceApp != nil || startDate != nil || endDate != nil || favoritesOnly else {
            return nil
        }

        return #Predicate<TranslationRecord> { record in
            (query.isEmpty || record.sourceText.localizedStandardContains(query) || record.translatedText.localizedStandardContains(query)) &&
            (sourceLang == nil || record.sourceLang == sourceLang!) &&
            (targetLang == nil || record.targetLang == targetLang!) &&
            (sourceApp == nil || record.sourceApp == sourceApp!) &&
            (startDate == nil || record.timestamp >= startDate!) &&
            (endDate == nil || record.timestamp <= endDate!) &&
            (!favoritesOnly || record.isFavorite)
        }
    }
}
