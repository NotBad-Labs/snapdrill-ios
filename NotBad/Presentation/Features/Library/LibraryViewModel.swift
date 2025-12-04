//
//  LibraryViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 3: ViewModel Dependency Injection
//

import SwiftUI
import SwiftData
import OSLog

// MARK: - LibraryViewModel

/// 题库 ViewModel
///
/// 负责管理错题列表的筛选、搜索、排序和批量操作。
///
/// ## 职责
///
/// - 错题筛选（学科、掌握程度、难度、来源）
/// - 关键词搜索
/// - 排序方式切换
/// - 批量删除操作
///
/// ## 依赖注入
///
/// 支持两种使用方式：
///
/// ```swift
/// // 方式1: 使用 DataProvider（推荐，支持测试）
/// let provider = SwiftDataReviewItemProvider(modelContext: context)
/// let viewModel = LibraryViewModel(dataProvider: provider)
/// let filtered = viewModel.filteredItems()
///
/// // 方式2: 传入 items（向后兼容）
/// let viewModel = LibraryViewModel()
/// let filtered = viewModel.filteredItems(from: items)
/// ```
@MainActor
@Observable
final class LibraryViewModel {

    // MARK: - Dependencies

    /// 数据提供者（可选，用于依赖注入）
    private var dataProvider: (any ReviewItemDataProviding)?

    // MARK: - Search State

    /// 搜索关键词
    var searchText = ""
    
    /// 搜索历史管理器
    private let searchHistoryManager = SearchHistoryManager.shared

    /// 是否正在搜索
    var isSearching: Bool {
        !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 高级搜索条件
    var advancedCriteria = SearchCriteria()

    /// 是否显示高级搜索
    var showAdvancedSearch = false

    // MARK: - Filter State

    /// 选中的学科
    var selectedSubject: Subject?

    /// 选中的掌握程度
    var selectedMastery: MasteryLevel?

    /// 选中的难度
    var selectedDifficulty: Difficulty?

    /// 选中的来源
    var selectedSource: Source?

    /// 是否只显示待复习
    var showPendingReviewOnly = false

    /// 是否有活跃的筛选条件
    var hasActiveFilters: Bool {
        selectedSubject != nil ||
        selectedMastery != nil ||
        selectedDifficulty != nil ||
        selectedSource != nil ||
        showPendingReviewOnly ||
        advancedCriteria.hasActiveFilters
    }

    /// 活跃筛选条件数量
    var activeFilterCount: Int {
        var count = 0
        if selectedSubject != nil { count += 1 }
        if selectedMastery != nil { count += 1 }
        if selectedDifficulty != nil { count += 1 }
        if selectedSource != nil { count += 1 }
        if showPendingReviewOnly { count += 1 }
        count += advancedCriteria.activeFilterCount
        return count
    }

    // MARK: - Sort State

    /// 排序方式
    var sortOption: SortOption = .createdAtDesc

    // MARK: - Selection State

    /// 是否处于选择模式
    var isSelectionMode = false

    /// 选中的项目 ID
    var selectedItemIds: Set<UUID> = []

    /// 选中数量
    var selectedCount: Int {
        selectedItemIds.count
    }
    
    // MARK: - Cache
    
    /// 缓存的筛选结果
    private var cachedFilteredItems: [ReviewItem] = []
    
    /// 缓存的数据源 hash（用于判断是否需要重新计算）
    private var cachedSourceHash: Int = 0
    
    /// 缓存的筛选条件 hash
    private var cachedFilterHash: Int = 0
    
    // MARK: - Database Search State
    
    /// 数据库搜索结果（穿透 Provider 直接查询数据库）
    private(set) var databaseSearchResults: [ReviewItem]?
    
    /// 搜索防抖任务
    private var searchDebounceTask: Task<Void, Never>?
    
    /// 是否正在执行数据库搜索
    private(set) var isSearchingDatabase = false

    // MARK: - Dependencies

    private var modelContext: ModelContext?

    // MARK: - Initialization

    /// 默认初始化（向后兼容）
    init() {}

    /// 依赖注入初始化（推荐用于测试）
    ///
    /// - Parameter dataProvider: 数据提供者
    init(dataProvider: any ReviewItemDataProviding) {
        self.dataProvider = dataProvider
    }

    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Data Access

    /// 获取所有错题
    ///
    /// 优先从 dataProvider 获取，否则返回空数组
    var items: [ReviewItem] {
        dataProvider?.items ?? []
    }

    /// 获取筛选后的错题（使用 DataProvider）
    ///
    /// - Returns: 筛选后的错题列表
    func filteredItems() -> [ReviewItem] {
        filteredItems(from: items)
    }

    // MARK: - Filtering
    
    /// 计算当前筛选条件的 hash 值
    private var currentFilterHash: Int {
        var hasher = Hasher()
        hasher.combine(searchText)
        hasher.combine(selectedSubject)
        hasher.combine(selectedMastery)
        hasher.combine(selectedDifficulty)
        hasher.combine(selectedSource)
        hasher.combine(showPendingReviewOnly)
        hasher.combine(sortOption)
        hasher.combine(advancedCriteria.hasActiveFilters)
        return hasher.finalize()
    }

    /// 根据筛选条件过滤错题（带缓存优化）
    ///
    /// - Parameter items: 原始错题列表
    /// - Returns: 过滤后的错题列表
    ///
    /// 使用 hash 值判断是否需要重新计算，避免 SwiftUI 每次 body 求值都触发筛选。
    func filteredItems(from items: [ReviewItem]) -> [ReviewItem] {
        // 计算数据源和筛选条件的 hash
        let sourceHash = items.count  // 简单用 count 作为 hash，因为 items 变化时 count 一定变
        let filterHash = currentFilterHash
        
        // 如果缓存有效，直接返回
        if sourceHash == cachedSourceHash && filterHash == cachedFilterHash {
            return cachedFilteredItems
        }
        
        // 重新计算
        var result = items

        // 搜索筛选
        if isSearching {
            let query = searchText.lowercased()
            result = result.filter { item in
                item.title.lowercased().contains(query) ||
                item.knowledgePoints.matches(searchText) ||
                item.note.lowercased().contains(query)
            }
        }

        // 学科筛选
        if let subject = selectedSubject {
            result = result.filter { $0.subject == subject }
        }

        // 掌握程度筛选
        if let mastery = selectedMastery {
            result = result.filter { $0.mastery == mastery }
        }

        // 难度筛选
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }

        // 来源筛选
        if let source = selectedSource {
            result = result.filter { $0.source == source }
        }

        // 待复习筛选
        if showPendingReviewOnly {
            result = result.filter { $0.needsReview }
        }

        // 高级搜索条件筛选
        if advancedCriteria.hasActiveFilters {
            result = advancedCriteria.filter(result)
        }

        // 排序
        result = sortItems(result)
        
        // 更新缓存
        cachedSourceHash = sourceHash
        cachedFilterHash = filterHash
        cachedFilteredItems = result

        return result
    }

    /// 排序错题
    private func sortItems(_ items: [ReviewItem]) -> [ReviewItem] {
        switch sortOption {
        case .createdAtDesc:
            items.sorted { $0.createdAt > $1.createdAt }
        case .createdAtAsc:
            items.sorted { $0.createdAt < $1.createdAt }
        case .titleAsc:
            items.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }
        case .masteryAsc:
            items.sorted { $0.masteryLevel < $1.masteryLevel }
        case .masteryDesc:
            items.sorted { $0.masteryLevel > $1.masteryLevel }
        case .difficultyDesc:
            items.sorted { $0.difficultyRaw > $1.difficultyRaw }
        case .reviewDateAsc:
            items.sorted { $0.nextReviewDate < $1.nextReviewDate }
        }
    }

    // MARK: - Database Search
    
    /// 执行数据库搜索（带防抖）
    ///
    /// 当搜索词变化时调用，会自动防抖 300ms 后执行数据库查询。
    /// 这解决了"搜索墙"问题 - 确保能搜到 Provider 缓存外的历史数据。
    ///
    /// - Note: 搜索结果存储在 `databaseSearchResults` 中
    func performDatabaseSearch() {
        // 取消之前的防抖任务
        searchDebounceTask?.cancel()
        
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果搜索词为空，清除数据库搜索结果
        guard !query.isEmpty else {
            databaseSearchResults = nil
            isSearchingDatabase = false
            return
        }
        
        // 防抖 300ms
        searchDebounceTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(300))
            
            guard !Task.isCancelled else { return }
            
            await self?.executeSearch(query: query)
        }
    }
    
    /// 执行实际的数据库搜索
    private func executeSearch(query: String) async {
        isSearchingDatabase = true
        defer { isSearchingDatabase = false }
        
        guard let provider = dataProvider else {
            // 如果没有 provider，回退到内存搜索
            databaseSearchResults = nil
            return
        }
        
        // 调用 Provider 的数据库搜索（穿透到 Repository）
        databaseSearchResults = provider.search(query: query)
    }
    
    /// 获取最终显示的数据
    ///
    /// 如果有数据库搜索结果，优先使用；否则使用 Provider 缓存数据。
    /// 这确保了搜索时能查到全部数据，浏览时使用高性能缓存。
    func displayItems(from items: [ReviewItem]) -> [ReviewItem] {
        // 如果正在搜索且有数据库结果，使用数据库结果
        if isSearching, let searchResults = databaseSearchResults {
            // 对搜索结果应用其他筛选条件（学科、掌握度等）
            return applyFiltersExceptSearch(to: searchResults)
        }
        
        // 否则使用常规的内存筛选
        return filteredItems(from: items)
    }
    
    /// 应用除搜索外的其他筛选条件
    private func applyFiltersExceptSearch(to items: [ReviewItem]) -> [ReviewItem] {
        var result = items
        
        // 学科筛选
        if let subject = selectedSubject {
            result = result.filter { $0.subject == subject }
        }
        
        // 掌握程度筛选
        if let mastery = selectedMastery {
            result = result.filter { $0.mastery == mastery }
        }
        
        // 难度筛选
        if let difficulty = selectedDifficulty {
            result = result.filter { $0.difficulty == difficulty }
        }
        
        // 来源筛选
        if let source = selectedSource {
            result = result.filter { $0.source == source }
        }
        
        // 待复习筛选
        if showPendingReviewOnly {
            result = result.filter { $0.needsReview }
        }
        
        // 高级搜索条件筛选
        if advancedCriteria.hasActiveFilters {
            result = advancedCriteria.filter(result)
        }
        
        // 排序
        return sortItems(result)
    }

    // MARK: - Filter Actions
    
    /// 提交搜索（保存到历史记录）
    ///
    /// 当用户按下回车确认搜索时调用，将搜索词保存到历史记录中。
    func submitSearch() {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        searchHistoryManager.addSearch(trimmed)
    }
    
    /// 从历史记录选择搜索词
    ///
    /// - Parameter query: 历史记录中的搜索词
    func selectFromHistory(_ query: String) {
        searchText = query
        searchHistoryManager.addSearch(query)
    }

    /// 选择学科
    func selectSubject(_ subject: Subject?) {
        selectedSubject = subject
    }

    /// 选择掌握程度
    func selectMastery(_ mastery: MasteryLevel?) {
        selectedMastery = mastery
    }

    /// 选择难度
    func selectDifficulty(_ difficulty: Difficulty?) {
        selectedDifficulty = difficulty
    }

    /// 选择来源
    func selectSource(_ source: Source?) {
        selectedSource = source
    }

    /// 重置所有筛选条件
    func resetFilters() {
        selectedSubject = nil
        selectedMastery = nil
        selectedDifficulty = nil
        selectedSource = nil
        showPendingReviewOnly = false
        searchText = ""
        advancedCriteria = SearchCriteria()
    }

    // MARK: - Selection Actions

    /// 切换选择模式
    func toggleSelectionMode() {
        isSelectionMode.toggle()
        if !isSelectionMode {
            selectedItemIds.removeAll()
        }
    }

    /// 切换单个项目的选中状态
    func toggleSelection(for itemId: UUID) {
        if selectedItemIds.contains(itemId) {
            selectedItemIds.remove(itemId)
        } else {
            selectedItemIds.insert(itemId)
        }
    }

    /// 全选
    func selectAll(from items: [ReviewItem]) {
        selectedItemIds = Set(items.map { $0.id })
    }

    /// 取消全选
    func deselectAll() {
        selectedItemIds.removeAll()
    }

    /// 检查项目是否被选中
    func isSelected(_ itemId: UUID) -> Bool {
        selectedItemIds.contains(itemId)
    }

    // MARK: - CRUD Actions

    /// 删除指定位置的错题
    func deleteItems(from items: [ReviewItem], at offsets: IndexSet) {
        guard let modelContext else { return }

        for index in offsets {
            modelContext.delete(items[index])
        }

        do {
            try modelContext.save()
        } catch {
            Logger.data.error("删除失败: \(error)")
        }
    }

    /// 删除单个错题
    func deleteItem(_ item: ReviewItem) {
        guard let modelContext else { return }

        modelContext.delete(item)

        do {
            try modelContext.save()
        } catch {
            Logger.data.error("删除失败: \(error)")
        }
    }

    /// 批量删除选中的错题
    func deleteSelectedItems(from items: [ReviewItem]) {
        guard let modelContext else { return }

        let itemsToDelete = items.filter { selectedItemIds.contains($0.id) }

        for item in itemsToDelete {
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
            selectedItemIds.removeAll()
            isSelectionMode = false
        } catch {
            Logger.data.error("批量删除失败: \(error)")
        }
    }
    
    /// 批量标记掌握程度
    ///
    /// - Parameters:
    ///   - items: 所有错题列表
    ///   - mastery: 要设置的掌握程度
    func markSelectedItems(from items: [ReviewItem], as mastery: MasteryLevel) {
        guard let modelContext else { return }
        
        let itemsToUpdate = items.filter { selectedItemIds.contains($0.id) }
        
        for item in itemsToUpdate {
            item.mastery = mastery
            item.updatedAt = Date()
        }
        
        do {
            try modelContext.save()
            selectedItemIds.removeAll()
            isSelectionMode = false
        } catch {
            Logger.data.error("批量标记失败: \(error)")
        }
    }

    // MARK: - Statistics

    /// 计算当前筛选结果的统计
    func computeFilteredStatistics(from items: [ReviewItem]) -> FilteredStatistics {
        let filtered = filteredItems(from: items)

        return FilteredStatistics(
            totalCount: items.count,
            filteredCount: filtered.count,
            masteredCount: filtered.filter { $0.isMastered }.count,
            pendingReviewCount: filtered.filter { $0.needsReview }.count
        )
    }
}

// MARK: - SortOption

/// 排序选项
enum SortOption: String, CaseIterable, Identifiable {
    case createdAtDesc
    case createdAtAsc
    case titleAsc
    case masteryAsc
    case masteryDesc
    case difficultyDesc
    case reviewDateAsc

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .createdAtDesc: String(localized: "sort_newest")
        case .createdAtAsc: String(localized: "sort_oldest")
        case .titleAsc: String(localized: "sort_title")
        case .masteryAsc: String(localized: "sort_mastery_asc")
        case .masteryDesc: String(localized: "sort_mastery_desc")
        case .difficultyDesc: String(localized: "sort_difficulty")
        case .reviewDateAsc: String(localized: "sort_review_needed")
        }
    }
    
    /// 简短名称（用于筛选栏按钮显示）
    var shortName: String {
        switch self {
        case .createdAtDesc: String(localized: "sort_short_newest")
        case .createdAtAsc: String(localized: "sort_short_oldest")
        case .titleAsc: String(localized: "sort_short_title")
        case .masteryAsc: String(localized: "sort_short_mastery_asc")
        case .masteryDesc: String(localized: "sort_short_mastery_desc")
        case .difficultyDesc: String(localized: "sort_short_difficulty")
        case .reviewDateAsc: String(localized: "sort_short_review")
        }
    }

    var icon: String {
        switch self {
        case .createdAtDesc: "arrow.down.circle"
        case .createdAtAsc: "arrow.up.circle"
        case .titleAsc: "textformat.abc"
        case .masteryAsc, .masteryDesc: "chart.bar"
        case .difficultyDesc: "flame"
        case .reviewDateAsc: "clock"
        }
    }
}

// MARK: - FilteredStatistics

/// 筛选结果统计
struct FilteredStatistics: Sendable, Equatable {
    let totalCount: Int
    let filteredCount: Int
    let masteredCount: Int
    let pendingReviewCount: Int

    /// 筛选率描述
    var filterDescription: String {
        if filteredCount == totalCount {
            return String(format: String(localized: "filter_total_count"), totalCount)
        } else {
            return String(format: String(localized: "filter_filtered_count"), filteredCount, totalCount)
        }
    }
}
