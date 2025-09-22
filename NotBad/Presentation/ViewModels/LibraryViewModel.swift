//
//  LibraryViewModel.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI
import Combine

/// 题库功能的视图模型
/// 负责管理题库相关的UI状态和业务逻辑协调
@MainActor
final class LibraryViewModel: ObservableObject {
    
    // MARK: - Published Properties (UI State)
    
    /// 题目列表
    @Published var reviewItems: [ReviewItem] = []
    
    /// 是否正在加载
    @Published var isLoading = false
    
    /// 是否显示搜索栏
    @Published var showSearchBar = false
    
    /// 搜索关键词
    @Published var searchText = ""
    
    /// 当前选择的筛选条件
    @Published var selectedSubject: ReviewItem.Subject?
    @Published var selectedDifficulty: ReviewItem.Difficulty?
    
    /// 是否显示筛选器
    @Published var showFilters = false
    
    /// 统计信息
    @Published var totalItems = 0
    @Published var reviewedItems = 0
    @Published var pendingItems = 0
    
    // MARK: - Dependencies
    
    private let reviewItemService: ReviewItemServicing
    private weak var coordinator: LibraryCoordinator?
    private var cancellables = Set<AnyCancellable>()
    private weak var errorHandler: AppErrorHandler?
    
    // MARK: - Initialization
    
    init(
        reviewItemService: ReviewItemServicing,
        coordinator: LibraryCoordinator
    ) {
        self.reviewItemService = reviewItemService
        self.coordinator = coordinator
        
        setupBindings()
    }

    /// 配置全局错误处理器（由视图在 onAppear 时注入）
    func configure(errorHandler: AppErrorHandler) {
        self.errorHandler = errorHandler
    }
    
    // MARK: - Lifecycle
    
    func onAppear() {
        Task {
            await loadReviewItems()
            await loadStatistics()
        }
    }
    
    // MARK: - Public Interface
    
    /// 加载题目列表
    func loadReviewItems() async {
        isLoading = true
        
        let timer = AppLogger.Timer("LibraryViewModel.loadReviewItems", domain: .viewModel)
        AppLogger.info(.viewModel, "LibraryViewModel starting loadReviewItems")
        
        do {
            // 构建查询条件并通过Service查询
            let criteria = ReviewItemQueryCriteria(
                subject: selectedSubject,
                difficulty: selectedDifficulty,
                proficiencyLevel: nil,
                tags: nil,
                dateRange: nil,
                searchText: searchText.isEmpty ? nil : searchText
            )
            let items = try await reviewItemService.getItemsByCriteria(criteria)
            
            reviewItems = items
            timer.stop(extra: "loaded \(items.count) items")
            
        } catch {
            AppLogger.error(.viewModel, "LibraryViewModel loadReviewItems failed: \(error)")
            errorHandler?.handle(error)
        }
        
        isLoading = false
    }
    
    /// 加载统计信息
    func loadStatistics() async {
        do {
            let stats = try await reviewItemService.getStatistics()
            
            totalItems = stats.total
            reviewedItems = stats.proficiencyBreakdown.proficient
            pendingItems = stats.total - stats.proficiencyBreakdown.proficient
            
            AppLogger.debug(.viewModel, "LibraryViewModel statistics loaded: total=\(totalItems), reviewed=\(reviewedItems), pending=\(pendingItems)")
            
        } catch {
            AppLogger.error(.viewModel, "LibraryViewModel loadStatistics failed: \(error)")
            print("加载统计信息失败：\(error)")
        }
    }
    
    /// 刷新数据
    func refresh() async {
        await loadReviewItems()
        await loadStatistics()
    }
    
    /// 删除题目
    func deleteItem(_ item: ReviewItem) async {
        do {
            try await reviewItemService.deleteReviewItem(id: item.id)
            await loadReviewItems()
            await loadStatistics()
            
        } catch {
            errorHandler?.handle(error)
        }
    }
    
    /// 切换搜索栏显示
    func toggleSearchBar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showSearchBar.toggle()
        }
        
        if !showSearchBar {
            searchText = ""
        }
    }
    
    /// 切换筛选器显示
    func toggleFilters() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showFilters.toggle()
        }
    }
    
    /// 清除筛选条件
    func clearFilters() {
        selectedSubject = nil
        selectedDifficulty = nil
        searchText = ""
        
        Task {
            await loadReviewItems()
        }
    }
    
    /// 应用筛选条件
    func applyFilters() {
        showFilters = false
        
        Task {
            await loadReviewItems()
        }
    }
    
    /// 导航到题目详情
    func navigateToDetail(_ item: ReviewItem) {
        coordinator?.coordinate(to: .detail(module: "library", id: item.id.value.uuidString))
    }
    
    /// 导航到添加新题目
    func navigateToAddItem() {
        coordinator?.coordinate(to: .saveReviewItem(content: ""))
    }
    
    /// 开始练习模式
    func startPracticeMode() {
        coordinator?.coordinate(to: .practiceMode)
    }
    
    // 错误清理由 AppErrorHandler 统一管理
    
    // MARK: - Private Methods
    
    /// 设置数据绑定
    private func setupBindings() {
        // 搜索文本变化时自动搜索（防抖）
        $searchText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                Task {
                    await self?.loadReviewItems()
                }
            }
            .store(in: &cancellables)
    }
    
    // 错误提示由 AppErrorHandler 统一处理
}

// MARK: - Supporting Extensions

extension LibraryViewModel {
    /// 获取筛选后的题目数量
    var filteredItemsCount: Int {
        reviewItems.count
    }
    
    /// 是否有应用筛选条件
    var hasActiveFilters: Bool {
        selectedSubject != nil || selectedDifficulty != nil || !searchText.isEmpty
    }
    
    /// 完成率百分比
    var completionPercentage: Double {
        guard totalItems > 0 else { return 0.0 }
        return Double(reviewedItems) / Double(totalItems) * 100.0
    }
}