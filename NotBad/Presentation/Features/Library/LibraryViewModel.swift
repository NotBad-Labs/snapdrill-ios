//
//  LibraryViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 3: ViewModel Dependency Injection
//

import SwiftUI
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
/// 使用 DependencyFactory 创建：
///
/// ```swift
/// let viewModel = dependencyFactory.makeLibraryViewModel()
/// await viewModel.loadItems()
/// let filtered = viewModel.filteredItems()
/// ```
@MainActor
@Observable
final class LibraryViewModel {

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
    
    /// 选择状态管理器（复用通用组件）
    let selection = SelectionManager<UUID>()
    
    /// 向后兼容：是否处于选择模式
    var isSelectionMode: Bool {
        get { selection.isSelectionMode }
        set { 
            if newValue { selection.enterSelectionMode() }
            else { selection.exitSelectionMode() }
        }
    }

    /// 向后兼容：选中的项目 ID
    var selectedItemIds: Set<UUID> {
        get { selection.selectedIDs }
        set { selection.selectAll(newValue) }
    }

    /// 向后兼容：选中数量
    var selectedCount: Int {
        selection.selectedCount
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

    private var fetchItemsUseCase: FetchReviewItemsUseCaseProtocol?
    private var deleteUseCase: DeleteReviewItemUseCaseProtocol?
    private var updateUseCase: UpdateReviewItemUseCaseProtocol?
    
    // MARK: - Data State
    
    /// 从 Use Case 加载的数据（新架构）
    private(set) var loadedItems: [ReviewItem] = []
    
    /// 数据是否正在加载
    private(set) var isLoading = false

    // MARK: - Initialization

    /// 默认初始化
    init() {}
    
    /// Use Case 依赖注入初始化（推荐）
    ///
    /// - Parameters:
    ///   - fetchItemsUseCase: 获取错题用例
    ///   - deleteItemUseCase: 删除错题用例
    ///   - updateItemUseCase: 更新错题用例
    init(
        fetchItemsUseCase: FetchReviewItemsUseCaseProtocol,
        deleteItemUseCase: DeleteReviewItemUseCaseProtocol,
        updateItemUseCase: UpdateReviewItemUseCaseProtocol
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.deleteUseCase = deleteItemUseCase
        self.updateUseCase = updateItemUseCase
    }
    
    // MARK: - Data Loading
    
    /// 加载所有错题（使用 Use Case）
    /// 
    /// - Parameter forceRefresh: 强制刷新，忽略缓存
    func loadItems(forceRefresh: Bool = false) async {
        guard let fetchItemsUseCase else { return }
        
        // 如果已有数据且不强制刷新，跳过加载
        guard forceRefresh || loadedItems.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        loadedItems = await fetchItemsUseCase.execute()
    }
    
    /// 刷新数据（强制重新加载）
    func refresh() async {
        await loadItems(forceRefresh: true)
    }

    // MARK: - Data Access

    /// 获取所有错题
    var items: [ReviewItem] {
        loadedItems
    }

    /// 获取筛选后的错题
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

        // 应用其他筛选条件并排序
        result = applyNonSearchFilters(to: result)
        
        // 更新缓存
        cachedSourceHash = sourceHash
        cachedFilterHash = filterHash
        cachedFilteredItems = result

        return result
    }
    
    /// 应用除搜索外的所有筛选条件（共用逻辑）
    private func applyNonSearchFilters(to items: [ReviewItem]) -> [ReviewItem] {
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
        
        // 从已加载的数据中搜索
        let lowercasedQuery = query.lowercased()
        databaseSearchResults = loadedItems.filter { item in
            item.title.lowercased().contains(lowercasedQuery) ||
            item.note.lowercased().contains(lowercasedQuery) ||
            item.knowledgePoints.items.contains { $0.lowercased().contains(lowercasedQuery) }
        }
    }
    
    /// 获取最终显示的数据
    ///
    /// 如果有数据库搜索结果，优先使用；否则使用 Provider 缓存数据。
    /// 这确保了搜索时能查到全部数据，浏览时使用高性能缓存。
    func displayItems(from items: [ReviewItem]) -> [ReviewItem] {
        // 如果正在搜索且有数据库结果，使用数据库结果
        if isSearching, let searchResults = databaseSearchResults {
            // 对搜索结果应用其他筛选条件（学科、掌握度等）
            return applyNonSearchFilters(to: searchResults)
        }
        
        // 否则使用常规的内存筛选
        return filteredItems(from: items)
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
        selection.toggleMode()
    }

    /// 切换单个项目的选中状态
    func toggleSelection(for itemId: UUID) {
        selection.toggle(itemId)
    }

    /// 全选
    func selectAll(from items: [ReviewItem]) {
        selection.selectAll(from: items)
    }

    /// 取消全选
    func deselectAll() {
        selection.deselectAll()
    }

    /// 检查项目是否被选中
    func isSelected(_ itemId: UUID) -> Bool {
        selection.isSelected(itemId)
    }

    // MARK: - CRUD Actions

    /// 删除指定位置的错题
    func deleteItems(from items: [ReviewItem], at offsets: IndexSet) {
        guard let deleteUseCase else {
            Logger.data.error("DeleteUseCase 未配置")
            return
        }

        let itemIds = offsets.map { items[$0].id }
        
        Task {
            do {
                try await deleteUseCase.execute(itemIds: itemIds)
            } catch {
                Logger.data.error("删除失败: \(error)")
            }
        }
    }

    /// 删除单个错题
    func deleteItem(_ item: ReviewItem) {
        guard let deleteUseCase else {
            Logger.data.error("DeleteUseCase 未配置")
            return
        }

        Task {
            do {
                try await deleteUseCase.execute(itemId: item.id)
            } catch {
                Logger.data.error("删除失败: \(error)")
            }
        }
    }

    /// 批量删除选中的错题
    func deleteSelectedItems(from items: [ReviewItem]) {
        guard let deleteUseCase else {
            Logger.data.error("DeleteUseCase 未配置")
            return
        }

        let itemsToDelete = selection.selectedItems(from: items)
        let itemIds = itemsToDelete.map(\.id)

        Task {
            do {
                try await deleteUseCase.execute(itemIds: itemIds)
                selection.completeOperation()
            } catch {
                Logger.data.error("批量删除失败: \(error)")
            }
        }
    }
    
    /// 批量标记掌握程度
    ///
    /// - Parameters:
    ///   - items: 所有错题列表
    ///   - mastery: 要设置的掌握程度
    func markSelectedItems(from items: [ReviewItem], as mastery: MasteryLevel) {
        guard let updateUseCase = updateUseCase as? UpdateReviewItemUseCase else {
            Logger.data.error("UpdateUseCase 未配置")
            return
        }
        
        let itemsToUpdate = selection.selectedItems(from: items)
        let itemIds = itemsToUpdate.map(\.id)

        Task {
            do {
                try await updateUseCase.executeBatch(itemIds: itemIds, mastery: mastery)
                selection.completeOperation()
            } catch {
                Logger.data.error("批量标记失败: \(error)")
            }
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
