//
//  LibraryViewModelTests.swift
//  NotBadTests
//
//  LibraryViewModel 单元测试
//

import Testing
import Foundation
@testable import NotBad

@Suite("LibraryViewModel 测试")
@MainActor
struct LibraryViewModelTests {

    // MARK: - 测试辅助方法

    private func createTestItems() -> [ReviewItem] {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!

        return [
            createItem(
                title: "数学函数",
                subject: .math,
                mastery: .mastered,
                difficulty: .hard,
                source: .exam,
                createdAt: now,
                needsReview: false
            ),
            createItem(
                title: "物理力学",
                subject: .physics,
                mastery: .partial,
                difficulty: .medium,
                source: .homework,
                createdAt: yesterday,
                needsReview: true
            ),
            createItem(
                title: "化学反应",
                subject: .chemistry,
                mastery: .none,
                difficulty: .easy,
                source: .textbook,
                createdAt: yesterday,
                needsReview: true
            )
        ]
    }

    private func createItem(
        title: String,
        subject: Subject,
        mastery: MasteryLevel,
        difficulty: Difficulty,
        source: Source,
        createdAt: Date,
        needsReview: Bool
    ) -> ReviewItem {
        let reviewItem = ReviewItem(
            title: title,
            mastery: mastery,
            subject: subject,
            difficulty: difficulty,
            source: source
        )
        reviewItem.createdAt = createdAt
        reviewItem.nextReviewDate = needsReview ? Date() : Calendar.current.date(byAdding: .day, value: 7, to: Date())!
        return reviewItem
    }

    // MARK: - 初始化测试

    @Test("初始状态正确")
    func initialState() {
        let viewModel = LibraryViewModel()

        #expect(viewModel.searchText == "")
        #expect(viewModel.selectedSubject == nil)
        #expect(viewModel.selectedMastery == nil)
        #expect(viewModel.selectedDifficulty == nil)
        #expect(viewModel.selectedSource == nil)
        #expect(viewModel.showPendingReviewOnly == false)
        #expect(viewModel.sortOption == .createdAtDesc)
        #expect(viewModel.isSelectionMode == false)
        #expect(viewModel.selectedItemIds.isEmpty)
    }

    // MARK: - 搜索测试

    @Test("isSearching 正确判断")
    func isSearchingProperty() {
        let viewModel = LibraryViewModel()

        #expect(viewModel.isSearching == false)

        viewModel.searchText = "函数"
        #expect(viewModel.isSearching == true)

        viewModel.searchText = "   "
        #expect(viewModel.isSearching == false)
    }

    @Test("搜索筛选标题")
    func searchFiltersTitle() {
        let viewModel = LibraryViewModel()
        viewModel.searchText = "函数"

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.title == "数学函数")
    }

    @Test("搜索不区分大小写")
    func searchCaseInsensitive() {
        let viewModel = LibraryViewModel()
        viewModel.searchText = "数学"

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
    }

    // MARK: - 筛选测试

    @Test("hasActiveFilters 正确判断")
    func hasActiveFiltersProperty() {
        let viewModel = LibraryViewModel()

        #expect(viewModel.hasActiveFilters == false)

        viewModel.selectedSubject = .math
        #expect(viewModel.hasActiveFilters == true)

        viewModel.selectedSubject = nil
        viewModel.showPendingReviewOnly = true
        #expect(viewModel.hasActiveFilters == true)
    }

    @Test("按学科筛选")
    func filterBySubject() {
        let viewModel = LibraryViewModel()
        viewModel.selectedSubject = .physics

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.subject == .physics)
    }

    @Test("按掌握程度筛选")
    func filterByMastery() {
        let viewModel = LibraryViewModel()
        viewModel.selectedMastery = .mastered

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.mastery == .mastered)
    }

    @Test("按难度筛选")
    func filterByDifficulty() {
        let viewModel = LibraryViewModel()
        viewModel.selectedDifficulty = .easy

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.difficulty == .easy)
    }

    @Test("按来源筛选")
    func filterBySource() {
        let viewModel = LibraryViewModel()
        viewModel.selectedSource = .exam

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.source == .exam)
    }

    @Test("待复习筛选")
    func filterByPendingReview() {
        let viewModel = LibraryViewModel()
        viewModel.showPendingReviewOnly = true

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 2)
        for item in filtered {
            #expect(item.needsReview == true)
        }
    }

    @Test("组合筛选")
    func combinedFilters() {
        let viewModel = LibraryViewModel()
        viewModel.selectedSubject = .physics
        viewModel.showPendingReviewOnly = true

        let items = createTestItems()
        let filtered = viewModel.filteredItems(from: items)

        #expect(filtered.count == 1)
        #expect(filtered.first?.subject == .physics)
        #expect(filtered.first?.needsReview == true)
    }

    @Test("resetFilters 重置所有筛选")
    func resetFiltersAction() {
        let viewModel = LibraryViewModel()
        viewModel.selectedSubject = .math
        viewModel.selectedMastery = .good
        viewModel.selectedDifficulty = .hard
        viewModel.searchText = "test"
        viewModel.showPendingReviewOnly = true

        viewModel.resetFilters()

        #expect(viewModel.selectedSubject == nil)
        #expect(viewModel.selectedMastery == nil)
        #expect(viewModel.selectedDifficulty == nil)
        #expect(viewModel.selectedSource == nil)
        #expect(viewModel.searchText == "")
        #expect(viewModel.showPendingReviewOnly == false)
    }

    // MARK: - 排序测试

    @Test("按创建时间降序排序")
    func sortByCreatedAtDesc() {
        let viewModel = LibraryViewModel()
        viewModel.sortOption = .createdAtDesc

        let items = createTestItems()
        let sorted = viewModel.filteredItems(from: items)

        for i in 1..<sorted.count {
            #expect(sorted[i-1].createdAt >= sorted[i].createdAt)
        }
    }

    @Test("按创建时间升序排序")
    func sortByCreatedAtAsc() {
        let viewModel = LibraryViewModel()
        viewModel.sortOption = .createdAtAsc

        let items = createTestItems()
        let sorted = viewModel.filteredItems(from: items)

        for i in 1..<sorted.count {
            #expect(sorted[i-1].createdAt <= sorted[i].createdAt)
        }
    }

    @Test("按掌握程度升序排序")
    func sortByMasteryAsc() {
        let viewModel = LibraryViewModel()
        viewModel.sortOption = .masteryAsc

        let items = createTestItems()
        let sorted = viewModel.filteredItems(from: items)

        for i in 1..<sorted.count {
            #expect(sorted[i-1].masteryLevel <= sorted[i].masteryLevel)
        }
    }

    @Test("按掌握程度降序排序")
    func sortByMasteryDesc() {
        let viewModel = LibraryViewModel()
        viewModel.sortOption = .masteryDesc

        let items = createTestItems()
        let sorted = viewModel.filteredItems(from: items)

        for i in 1..<sorted.count {
            #expect(sorted[i-1].masteryLevel >= sorted[i].masteryLevel)
        }
    }

    @Test("按难度降序排序")
    func sortByDifficultyDesc() {
        let viewModel = LibraryViewModel()
        viewModel.sortOption = .difficultyDesc

        let items = createTestItems()
        let sorted = viewModel.filteredItems(from: items)

        for i in 1..<sorted.count {
            #expect(sorted[i-1].difficultyRaw >= sorted[i].difficultyRaw)
        }
    }

    // MARK: - 选择模式测试

    @Test("toggleSelectionMode 切换模式")
    func toggleSelectionModeAction() {
        let viewModel = LibraryViewModel()

        viewModel.toggleSelectionMode()
        #expect(viewModel.isSelectionMode == true)

        viewModel.toggleSelectionMode()
        #expect(viewModel.isSelectionMode == false)
    }

    @Test("退出选择模式清空选中")
    func exitSelectionModeClearsSelection() {
        let viewModel = LibraryViewModel()
        viewModel.isSelectionMode = true
        viewModel.selectedItemIds.insert(UUID())

        viewModel.toggleSelectionMode()

        #expect(viewModel.selectedItemIds.isEmpty)
    }

    @Test("toggleSelection 切换选中状态")
    func toggleSelectionAction() {
        let viewModel = LibraryViewModel()
        let id = UUID()

        viewModel.toggleSelection(for: id)
        #expect(viewModel.selectedItemIds.contains(id))

        viewModel.toggleSelection(for: id)
        #expect(!viewModel.selectedItemIds.contains(id))
    }

    @Test("selectAll 全选")
    func selectAllAction() {
        let viewModel = LibraryViewModel()
        let items = createTestItems()

        viewModel.selectAll(from: items)

        #expect(viewModel.selectedItemIds.count == items.count)
    }

    @Test("deselectAll 取消全选")
    func deselectAllAction() {
        let viewModel = LibraryViewModel()
        viewModel.selectedItemIds.insert(UUID())
        viewModel.selectedItemIds.insert(UUID())

        viewModel.deselectAll()

        #expect(viewModel.selectedItemIds.isEmpty)
    }

    @Test("isSelected 正确判断")
    func isSelectedCheck() {
        let viewModel = LibraryViewModel()
        let id1 = UUID()
        let id2 = UUID()
        viewModel.selectedItemIds.insert(id1)

        #expect(viewModel.isSelected(id1) == true)
        #expect(viewModel.isSelected(id2) == false)
    }

    @Test("selectedCount 计算正确")
    func selectedCountCalculation() {
        let viewModel = LibraryViewModel()

        #expect(viewModel.selectedCount == 0)

        viewModel.selectedItemIds.insert(UUID())
        viewModel.selectedItemIds.insert(UUID())

        #expect(viewModel.selectedCount == 2)
    }

    // MARK: - 筛选器方法测试

    @Test("selectSubject 设置学科")
    func selectSubjectAction() {
        let viewModel = LibraryViewModel()

        viewModel.selectSubject(.math)
        #expect(viewModel.selectedSubject == .math)

        viewModel.selectSubject(nil)
        #expect(viewModel.selectedSubject == nil)
    }

    @Test("selectMastery 设置掌握程度")
    func selectMasteryAction() {
        let viewModel = LibraryViewModel()

        viewModel.selectMastery(.good)
        #expect(viewModel.selectedMastery == .good)
    }

    @Test("selectDifficulty 设置难度")
    func selectDifficultyAction() {
        let viewModel = LibraryViewModel()

        viewModel.selectDifficulty(.hard)
        #expect(viewModel.selectedDifficulty == .hard)
    }

    @Test("selectSource 设置来源")
    func selectSourceAction() {
        let viewModel = LibraryViewModel()

        viewModel.selectSource(.exam)
        #expect(viewModel.selectedSource == .exam)
    }

    // MARK: - 统计测试

    @Test("computeFilteredStatistics 计算正确")
    func computeFilteredStatisticsCalculation() {
        let viewModel = LibraryViewModel()
        let items = createTestItems()

        let stats = viewModel.computeFilteredStatistics(from: items)

        #expect(stats.totalCount == 3)
        #expect(stats.filteredCount == 3)
    }

    @Test("筛选后统计正确")
    func filteredStatisticsAfterFilter() {
        let viewModel = LibraryViewModel()
        viewModel.selectedSubject = .math

        let items = createTestItems()
        let stats = viewModel.computeFilteredStatistics(from: items)

        #expect(stats.totalCount == 3)
        #expect(stats.filteredCount == 1)
    }

    // MARK: - SortOption 测试

    @Test("SortOption 所有选项都有属性")
    func sortOptionProperties() {
        for option in SortOption.allCases {
            #expect(!option.displayName.isEmpty)
            #expect(!option.icon.isEmpty)
        }
    }

    // MARK: - FilteredStatistics 测试

    @Test("filterDescription 格式正确")
    func filterDescriptionFormat() {
        let stats1 = FilteredStatistics(
            totalCount: 10,
            filteredCount: 10,
            masteredCount: 5,
            pendingReviewCount: 2
        )
        #expect(stats1.filterDescription == "共 10 道")

        let stats2 = FilteredStatistics(
            totalCount: 10,
            filteredCount: 5,
            masteredCount: 3,
            pendingReviewCount: 1
        )
        #expect(stats2.filterDescription == "筛选出 5/10 道")
    }
}
