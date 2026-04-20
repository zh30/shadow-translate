import SharedCore
import SwiftUI

public struct MainWindowView: View {
    @State private var selectedRecord: MockRecord?
    @State private var searchText = ""
    @State private var selectedFilter: SidebarFilter = .all

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            recordList
        } detail: {
            detailView
        }
        .searchable(text: $searchText, prompt: "搜索翻译历史…")
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(SidebarFilter.allCases, selection: $selectedFilter) { filter in
            switch filter {
            case .all:
                Label("全部", systemImage: "clock.arrow.circlepath").tag(filter)
            case .favorites:
                Label("收藏", systemImage: "star").tag(filter)
            case .recent:
                Label("最近 7 天", systemImage: "calendar").tag(filter)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Shadow Translate")
    }

    // MARK: - Record List

    private var recordList: some View {
        List(filteredRecords, selection: $selectedRecord) { record in
            recordRow(record)
                .tag(record)
        }
        .listStyle(.inset)
        .overlay {
            if filteredRecords.isEmpty {
                ContentUnavailableView(
                    "暂无翻译记录",
                    systemImage: "character.bubble",
                    description: Text("使用 ⌘⇧T 翻译选中文本")
                )
            }
        }
    }

    private func recordRow(_ record: MockRecord) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.sourcePreview)
                    .font(.body)
                    .lineLimit(1)
                Text(record.targetPreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.timestampFormatted)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if record.isFavorite {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                }
            }
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    // MARK: - Detail

    private var detailView: some View {
        Group {
            if let record = selectedRecord {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        sourceSection(record)
                        targetSection(record)
                    }
                    .padding(Theme.Spacing.xl)
                }
            } else {
                ContentUnavailableView(
                    "选择一条翻译记录",
                    systemImage: "character.bubble.left.and.bubble.right",
                    description: Text("从列表中选择一条记录查看详情")
                )
            }
        }
    }

    private func sourceSection(_ record: MockRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label("原文", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.sourceLanguage.localizedName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(record.sourceText)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private func targetSection(_ record: MockRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label("译文", systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(record.targetLanguage.localizedName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(record.translatedText)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    // MARK: - Data

    private var filteredRecords: [MockRecord] {
        let records = MockRecord.samples
        let filtered: [MockRecord]
        switch selectedFilter {
        case .all: filtered = records
        case .favorites: filtered = records.filter(\.isFavorite)
        case .recent:
            let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: .now) ?? .now
            filtered = records.filter { $0.timestamp >= cutoff }
        }
        if searchText.isEmpty { return filtered }
        return filtered.filter {
            $0.sourceText.localizedCaseInsensitiveContains(searchText)
                || $0.translatedText.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Sidebar Filter

public enum SidebarFilter: String, CaseIterable, Hashable, Identifiable {
    public var id: String { rawValue }
    case all
    case favorites
    case recent
}

// MARK: - Mock Data (Stage 5 will replace with PersistenceKit)

public struct MockRecord: Hashable, Identifiable, Sendable {
    public let id = UUID()
    public let sourceText: String
    public let translatedText: String
    public let sourceLanguage: Language
    public let targetLanguage: Language
    public let timestamp: Date
    public let isFavorite: Bool

    public var sourcePreview: String { String(sourceText.prefix(50)) }
    public var targetPreview: String { String(translatedText.prefix(50)) }
    public var timestampFormatted: String {
        timestamp.formatted(.dateTime.hour().minute())
    }

    public static let samples: [MockRecord] = [
        MockRecord(
            sourceText: "The quick brown fox jumps over the lazy dog.",
            translatedText: "敏捷的棕色狐狸跳过了懒狗。",
            sourceLanguage: .en,
            targetLanguage: .zh,
            timestamp: Date().addingTimeInterval(-300),
            isFavorite: true
        ),
        MockRecord(
            sourceText: "Artificial intelligence is transforming every industry.",
            translatedText: "人工智能正在改变每一个行业。",
            sourceLanguage: .en,
            targetLanguage: .zh,
            timestamp: Date().addingTimeInterval(-1800),
            isFavorite: false
        ),
        MockRecord(
            sourceText: "SwiftUI makes it easy to build great apps across all Apple platforms.",
            translatedText: "SwiftUI 让跨所有 Apple 平台构建优秀应用变得简单。",
            sourceLanguage: .en,
            targetLanguage: .zh,
            timestamp: Date().addingTimeInterval(-7200),
            isFavorite: false
        ),
    ]
}