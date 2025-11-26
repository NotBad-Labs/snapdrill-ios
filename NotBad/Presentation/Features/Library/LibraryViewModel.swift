//
//  LibraryViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

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
/// ## 使用示例
///
/// ```swift
/// struct LibraryView: View {
///     @Query private var items: [ReviewItem]
///     @State private var viewModel = LibraryViewModel()
///
///     var body: some View {
///         List(viewModel.filteredItems(from: items)) { item in
///             // ...
///         }
///         .searchable(text: $viewModel.searchText)
///     }
/// }
/// ```
@MainActor
@Observable
final class LibraryViewModel {
    
    // MARK: - Search State
    
    /// 搜索关键词
    var searchText = ""
    
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
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    /// 配置 ModelContext
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Filtering
    
    /// 根据筛选条件过滤错题
    ///
    /// - Parameter items: 原始错题列表
    /// - Returns: 过滤后的错题列表
    func filteredItems(from items: [ReviewItem]) -> [ReviewItem] {
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
    
    // MARK: - Filter Actions
    
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
            #if DEBUG
            print("❌ 删除失败: \(error)")
            #endif
        }
    }
    
    /// 删除单个错题
    func deleteItem(_ item: ReviewItem) {
        guard let modelContext else { return }
        
        modelContext.delete(item)
        
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("❌ 删除失败: \(error)")
            #endif
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
            #if DEBUG
            print("❌ 批量删除失败: \(error)")
            #endif
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
    case createdAtDesc = "最新添加"
    case createdAtAsc = "最早添加"
    case titleAsc = "标题排序"
    case masteryAsc = "掌握程度↑"
    case masteryDesc = "掌握程度↓"
    case difficultyDesc = "难度最高"
    case reviewDateAsc = "最需复习"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
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
            return "共 \(totalCount) 道"
        } else {
            return "筛选出 \(filteredCount)/\(totalCount) 道"
        }
    }
}
