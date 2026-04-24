import AccessibilityKit
import AppKit
import PersistenceKit
import SharedCore
import SwiftUI

public struct MainWindowView: View {
    @Environment(AppState.self) private var appState
    @State private var records: [TranslationRecord] = []
    @State private var selectedRecordIDs = Set<UUID>()
    @State private var searchText = ""
    @State private var selectedFilter: SidebarFilter = .all
    @State private var selectedSourceLanguage: Language = .auto
    @State private var selectedTargetLanguage: Language = .auto
    @State private var selectedSourceApp = allSourceAppsValue
    @State private var sourceApps: [String] = []
    @State private var isDateFilterEnabled = false
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var tagText = ""
    @State private var retranslationIDs = Set<UUID>()
    @State private var errorMessage: String?

    private static let allSourceAppsValue = "__all_source_apps__"
    private let store = HistoryStore.shared

    public init() {}

    public var body: some View {
        NavigationSplitView {
            sidebar
        } content: {
            if selectedFilter == .analytics {
                analyticsDashboard
            } else {
                recordList
            }
        } detail: {
            if selectedFilter == .analytics {
                ContentUnavailableView(
                    "历史分析",
                    systemImage: "chart.bar.xaxis",
                    description: Text("左侧显示当前历史记录的统计概览")
                )
            } else {
                detailView
            }
        }
        .searchable(text: $searchText, prompt: "搜索翻译历史…")
        .toolbar { toolbarContent }
        .task { loadRecords() }
        .onChange(of: searchText) { _, _ in loadRecords() }
        .onChange(of: selectedFilter) { _, _ in loadRecords() }
        .onChange(of: selectedSourceLanguage) { _, _ in loadRecords() }
        .onChange(of: selectedTargetLanguage) { _, _ in loadRecords() }
        .onChange(of: selectedSourceApp) { _, _ in loadRecords() }
        .onChange(of: isDateFilterEnabled) { _, _ in loadRecords() }
        .onChange(of: startDate) { _, _ in loadRecords() }
        .onChange(of: endDate) { _, _ in loadRecords() }
        .alert("历史记录操作失败", isPresented: .constant(errorMessage != nil)) {
            Button("好") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        List(SidebarFilter.allCases, selection: $selectedFilter) { filter in
            Label(filter.title, systemImage: filter.systemImage).tag(filter)
        }
        .listStyle(.sidebar)
        .navigationTitle("Shadow Translate")
    }

    private var recordList: some View {
        VStack(spacing: 0) {
            filterBar
            List(records, selection: $selectedRecordIDs) { record in
                recordRow(record)
                    .tag(record.id)
            }
            .listStyle(.inset)
            .overlay {
                if records.isEmpty {
                    ContentUnavailableView(
                        "暂无翻译记录",
                        systemImage: "character.bubble",
                        description: Text("使用 ⌘⇧T 翻译选中文本")
                    )
                }
            }
        }
    }

    private var analyticsDashboard: some View {
        let analytics = HistoryAnalytics(records: records)
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text("历史分析")
                    .font(.title2.bold())

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: Theme.Spacing.md)], spacing: Theme.Spacing.md) {
                    metricCard("总翻译", value: "\(analytics.totalCount)", systemImage: "text.bubble")
                    metricCard("收藏", value: "\(analytics.favoriteCount)", systemImage: "star")
                    metricCard("重复翻译", value: "\(analytics.duplicateCount)", systemImage: "arrow.triangle.2.circlepath")
                    metricCard("近 7 天", value: "\(analytics.recentSevenDayTotal)", systemImage: "calendar")
                }

                dashboardSection("近 7 天趋势", systemImage: "chart.line.uptrend.xyaxis") {
                    ForEach(analytics.dailyCounts, id: \.day) { item in
                        distributionRow(item.day, count: item.count, maxCount: analytics.maxDailyCount)
                    }
                }

                dashboardSection("常用目标语言", systemImage: "character.book.closed") {
                    ForEach(analytics.topTargetLanguages, id: \.label) { item in
                        distributionRow(item.label, count: item.count, maxCount: analytics.maxTargetLanguageCount)
                    }
                }

                dashboardSection("常用来源 App", systemImage: "app.badge") {
                    ForEach(analytics.topSourceApps, id: \.label) { item in
                        distributionRow(item.label, count: item.count, maxCount: analytics.maxSourceAppCount)
                    }
                }
            }
            .padding(Theme.Spacing.xl)
        }
    }

    private func metricCard(_ title: String, value: String, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2.bold())
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.Spacing.md)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }

    private func dashboardSection<Content: View>(
        _ title: String,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label(title, systemImage: systemImage)
                .font(.headline)
            content()
        }
    }

    private func distributionRow(_ label: String, count: Int, maxCount: Int) -> some View {
        HStack(spacing: Theme.Spacing.sm) {
            Text(label)
                .frame(width: 96, alignment: .leading)
                .lineLimit(1)
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.accentColor.opacity(0.35))
                    .frame(width: maxCount > 0 ? proxy.size.width * CGFloat(count) / CGFloat(maxCount) : 0)
            }
            .frame(height: 8)
            Text("\(count)")
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private var filterBar: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Picker("源语言", selection: $selectedSourceLanguage) {
                ForEach(Language.allCases, id: \.self) { lang in
                    Text(lang.localizedName).tag(lang)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Picker("目标语言", selection: $selectedTargetLanguage) {
                ForEach(Language.allCases, id: \.self) { lang in
                    Text(lang.localizedName).tag(lang)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Picker("来源 App", selection: $selectedSourceApp) {
                Text("全部 App").tag(Self.allSourceAppsValue)
                ForEach(sourceApps, id: \.self) { appName in
                    Text(appName).tag(appName)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)

            Toggle("日期", isOn: $isDateFilterEnabled)
                .toggleStyle(.checkbox)

            if isDateFilterEnabled {
                DatePicker("开始", selection: $startDate, displayedComponents: .date)
                    .labelsHidden()
                DatePicker("结束", selection: $endDate, displayedComponents: .date)
                    .labelsHidden()
            }

            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
    }

    private func recordRow(_ record: TranslationRecord) -> some View {
        HStack(spacing: Theme.Spacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.sourceText)
                    .font(.body)
                    .lineLimit(1)
                Text(record.translatedText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(record.timestamp.formatted(.dateTime.hour().minute()))
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

    private var detailView: some View {
        Group {
            if let record = selectedRecord {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                        actionButtons(record)
                        sourceSection(record)
                        targetSection(record)
                        tagSection(record)
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

    private func actionButtons(_ record: TranslationRecord) -> some View {
        HStack {
            Button {
                copy(record.sourceText)
            } label: {
                Label("复制原文", systemImage: "doc.on.doc")
            }

            Button {
                copy(record.translatedText)
            } label: {
                Label("复制译文", systemImage: "doc.on.doc")
            }

            Button {
                Task { await insert(record.translatedText) }
            } label: {
                Label("插入", systemImage: "text.cursor")
            }

            Button {
                Task { await retranslate(record) }
            } label: {
                if retranslationIDs.contains(record.id) {
                    Label("重新翻译", systemImage: "arrow.triangle.2.circlepath")
                } else {
                    Label("重新翻译", systemImage: "arrow.triangle.2.circlepath")
                }
            }
            .disabled(!appState.modelState.isReady || retranslationIDs.contains(record.id))

            Button {
                toggleFavorite(record.id)
            } label: {
                Label(record.isFavorite ? "取消收藏" : "收藏", systemImage: record.isFavorite ? "star.slash" : "star")
            }

            Button(role: .destructive) {
                delete(record.id)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
        .buttonStyle(.bordered)
    }

    private func sourceSection(_ record: TranslationRecord) -> some View {
        textSection(title: "原文", text: record.sourceText, language: record.sourceLanguage)
    }

    private func targetSection(_ record: TranslationRecord) -> some View {
        textSection(title: "译文", text: record.translatedText, language: record.targetLanguage)
    }

    private func textSection(title: String, text: String, language: Language) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Label(title, systemImage: "text.alignleft")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(language.localizedName)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Text(text)
                .font(.body)
                .textSelection(.enabled)
        }
    }

    private func tagSection(_ record: TranslationRecord) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Label("标签", systemImage: "tag")
                .font(.caption)
                .foregroundStyle(.secondary)

            if record.tags.isEmpty {
                Text("暂无标签")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            } else {
                HStack(spacing: Theme.Spacing.xs) {
                    ForEach(record.tags.map(\.name).sorted(), id: \.self) { tag in
                        Button {
                            removeTag(tag, from: record.id)
                        } label: {
                            Label(tag, systemImage: "xmark")
                                .labelStyle(.titleAndIcon)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }

            HStack {
                TextField("添加标签", text: $tagText)
                    .textFieldStyle(.roundedBorder)
                Button("添加") {
                    addTag(record.id)
                }
                .disabled(tagText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItemGroup {
            Button {
                loadRecords()
            } label: {
                Label("刷新", systemImage: "arrow.clockwise")
            }

            Button(role: .destructive) {
                deleteSelected()
            } label: {
                Label("删除所选", systemImage: "trash")
            }
            .disabled(selectedRecordIDs.isEmpty)

            Menu {
                Button("导出 JSON…") { export(format: .json) }
                Button("导出 CSV…") { export(format: .csv) }
            } label: {
                Label("导出", systemImage: "square.and.arrow.up")
            }

            Button(role: .destructive) {
                clearHistory()
            } label: {
                Label("清空", systemImage: "trash")
            }
        }
    }

    private var selectedRecord: TranslationRecord? {
        guard let id = selectedRecordIDs.first else { return nil }
        return records.first { $0.id == id }
    }

    private func loadRecords() {
        do {
            sourceApps = try store.sourceApps()
            if selectedSourceApp != Self.allSourceAppsValue, !sourceApps.contains(selectedSourceApp) {
                selectedSourceApp = Self.allSourceAppsValue
            }
            let limit = selectedFilter == .analytics ? 10_000 : 500
            records = try store.fetchAll(limit: limit, filters: currentFilters)
            selectedRecordIDs = selectedRecordIDs.filter { selectedID in
                records.contains { $0.id == selectedID }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private var currentFilters: HistoryFilters {
        let recentStart = Calendar.current.date(byAdding: .day, value: -7, to: Date())
        let normalizedStart = Calendar.current.startOfDay(for: startDate)
        let normalizedEnd = Calendar.current.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: endDate
        ) ?? endDate
        return HistoryFilters(
            query: searchText,
            sourceLang: selectedSourceLanguage == .auto ? nil : selectedSourceLanguage,
            targetLang: selectedTargetLanguage == .auto ? nil : selectedTargetLanguage,
            sourceApp: selectedSourceApp == Self.allSourceAppsValue ? nil : selectedSourceApp,
            startDate: selectedFilter == .recent ? recentStart : (isDateFilterEnabled ? normalizedStart : nil),
            endDate: isDateFilterEnabled ? normalizedEnd : nil,
            favoritesOnly: selectedFilter == .favorites
        )
    }

    private func copy(_ text: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
    }

    private func insert(_ text: String) async {
        do {
            try await AXReplacer().replaceSelectedText(text)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func retranslate(_ record: TranslationRecord) async {
        guard appState.modelState.isReady else {
            errorMessage = "模型尚未就绪"
            return
        }

        retranslationIDs.insert(record.id)
        defer { retranslationIDs.remove(record.id) }

        var translatedText = ""
        let stream = await appState.inference.translate(
            text: record.sourceText,
            source: record.sourceLanguage,
            target: record.targetLanguage
        )
        for await token in stream {
            translatedText += token
        }

        guard !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "重新翻译未返回结果"
            return
        }

        do {
            _ = try await store.makeWriter().insert(
                sourceText: record.sourceText,
                translatedText: translatedText,
                sourceLang: record.sourceLanguage,
                targetLang: record.targetLanguage,
                sourceApp: record.sourceApp
            )
            loadRecords()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func toggleFavorite(_ id: UUID) {
        Task {
            do {
                try await store.makeWriter().toggleFavorite(id)
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func addTag(_ id: UUID) {
        let tag = tagText.trimmingCharacters(in: .whitespacesAndNewlines)
        Task {
            do {
                try await store.makeWriter().addTag(tag, to: id)
                tagText = ""
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func removeTag(_ tag: String, from id: UUID) {
        Task {
            do {
                try await store.makeWriter().removeTag(tag, from: id)
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func delete(_ id: UUID) {
        Task {
            do {
                try await store.makeWriter().delete(id)
                selectedRecordIDs.remove(id)
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func deleteSelected() {
        let ids = Array(selectedRecordIDs)
        Task {
            do {
                try await store.makeWriter().delete(ids: ids)
                selectedRecordIDs.removeAll()
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func clearHistory() {
        Task {
            do {
                try await store.makeWriter().clearAll()
                selectedRecordIDs.removeAll()
                loadRecords()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private enum ExportFormat {
        case json
        case csv

        var fileExtension: String {
            switch self {
            case .json: "json"
            case .csv: "csv"
            }
        }
    }

    private func export(format: ExportFormat) {
        do {
            let data: Data
            switch format {
            case .json:
                data = try store.exportJSON(filters: currentFilters)
            case .csv:
                data = try store.exportCSV(filters: currentFilters)
            }

            let panel = NSSavePanel()
            panel.allowedContentTypes = [.init(filenameExtension: format.fileExtension)!]
            panel.nameFieldStringValue = "shadow-translate-history.\(format.fileExtension)"
            if panel.runModal() == .OK, let url = panel.url {
                try data.write(to: url, options: .atomic)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

public enum SidebarFilter: String, CaseIterable, Hashable, Identifiable {
    public var id: String { rawValue }
    case all
    case favorites
    case recent
    case analytics

    var title: String {
        switch self {
        case .all: "全部"
        case .favorites: "收藏"
        case .recent: "最近 7 天"
        case .analytics: "分析"
        }
    }

    var systemImage: String {
        switch self {
        case .all: "clock.arrow.circlepath"
        case .favorites: "star"
        case .recent: "calendar"
        case .analytics: "chart.bar.xaxis"
        }
    }
}

private struct HistoryAnalytics {
    struct CountItem {
        let label: String
        let count: Int
    }

    struct DailyCount {
        let day: String
        let count: Int
    }

    let totalCount: Int
    let favoriteCount: Int
    let duplicateCount: Int
    let recentSevenDayTotal: Int
    let dailyCounts: [DailyCount]
    let topTargetLanguages: [CountItem]
    let topSourceApps: [CountItem]

    var maxDailyCount: Int { dailyCounts.map(\.count).max() ?? 0 }
    var maxTargetLanguageCount: Int { topTargetLanguages.map(\.count).max() ?? 0 }
    var maxSourceAppCount: Int { topSourceApps.map(\.count).max() ?? 0 }

    init(records: [TranslationRecord], calendar: Calendar = .current) {
        totalCount = records.count
        favoriteCount = records.filter(\.isFavorite).count

        let duplicateGroups = Dictionary(grouping: records) {
            "\($0.sourceText)\u{1f}\($0.sourceLanguage.rawValue)\u{1f}\($0.targetLanguage.rawValue)"
        }
        duplicateCount = duplicateGroups.values.filter { $0.count > 1 }.reduce(0) { $0 + $1.count }

        let today = calendar.startOfDay(for: Date())
        let lastSevenDays = (0..<7).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        dailyCounts = lastSevenDays.map { day in
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? day
            let count = records.filter { $0.timestamp >= day && $0.timestamp < nextDay }.count
            return DailyCount(day: day.formatted(.dateTime.month().day()), count: count)
        }
        recentSevenDayTotal = dailyCounts.reduce(0) { $0 + $1.count }

        topTargetLanguages = Self.topCounts(records.map { $0.targetLanguage.localizedName })
        topSourceApps = Self.topCounts(records.map { record in
            let appName = record.sourceApp?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let appName, !appName.isEmpty {
                return appName
            }
            return "未知 App"
        })
    }

    private static func topCounts(_ labels: [String], limit: Int = 5) -> [CountItem] {
        Dictionary(grouping: labels, by: { $0 })
            .map { CountItem(label: $0.key, count: $0.value.count) }
            .sorted {
                if $0.count == $1.count {
                    return $0.label < $1.label
                }
                return $0.count > $1.count
            }
            .prefix(limit)
            .map { $0 }
    }
}
