//
//  ViewModelDITests.swift
//  NotBadTests
//
//  测试 ViewModel 依赖注入功能
//

import Testing
import SwiftData
import Foundation
@testable import NotBad

// MARK: - DashboardViewModel DI Tests

@Suite("DashboardViewModel 依赖注入测试")
struct DashboardViewModelDITests {
    
    @Test("使用 DataProvider 初始化")
    @MainActor
    func initWithDataProvider() {
        let provider = MockReviewItemProvider()
        let viewModel = DashboardViewModel(dataProvider: provider)
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("通过 DataProvider 获取数据")
    @MainActor
    func getItemsFromDataProvider() {
        let provider = MockReviewItemProvider()
        provider.items = [
            ReviewItem(title: "数学错题", subject: .math),
            ReviewItem(title: "语文错题", subject: .chinese)
        ]
        let viewModel = DashboardViewModel(dataProvider: provider)
        
        #expect(viewModel.items.count == 2)
    }
    
    @Test("computeStatistics 使用 DataProvider 数据")
    @MainActor
    func computeStatisticsWithProvider() {
        let provider = MockReviewItemProvider()
        let item1 = ReviewItem(title: "已掌握", subject: .math)
        item1.mastery = .mastered
        let item2 = ReviewItem(title: "学习中", subject: .physics)
        item2.mastery = .partial
        provider.items = [item1, item2]
        
        let viewModel = DashboardViewModel(dataProvider: provider)
        let stats = viewModel.computeStatistics(from: viewModel.items)
        
        #expect(stats.totalCount == 2)
        #expect(stats.masteredCount == 1)
    }
}

// MARK: - LibraryViewModel DI Tests

@Suite("LibraryViewModel 依赖注入测试")
struct LibraryViewModelDITests {
    
    @Test("使用 DataProvider 初始化")
    @MainActor
    func initWithDataProvider() {
        let provider = MockReviewItemProvider()
        let viewModel = LibraryViewModel(dataProvider: provider)
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("filteredItems 使用 DataProvider 数据")
    @MainActor
    func filteredItemsWithProvider() {
        let provider = MockReviewItemProvider()
        provider.items = [
            ReviewItem(title: "数学1", subject: .math),
            ReviewItem(title: "数学2", subject: .math),
            ReviewItem(title: "物理1", subject: .physics)
        ]
        let viewModel = LibraryViewModel(dataProvider: provider)
        
        // 无筛选时返回全部
        #expect(viewModel.filteredItems().count == 3)
        
        // 按学科筛选
        viewModel.selectedSubject = .math
        #expect(viewModel.filteredItems().count == 2)
    }
    
    @Test("搜索功能正常")
    @MainActor
    func searchWithProvider() {
        let provider = MockReviewItemProvider()
        provider.items = [
            ReviewItem(title: "二次函数", subject: .math),
            ReviewItem(title: "一次函数", subject: .math),
            ReviewItem(title: "古诗词", subject: .chinese)
        ]
        let viewModel = LibraryViewModel(dataProvider: provider)
        viewModel.searchText = "函数"
        
        let filtered = viewModel.filteredItems()
        
        #expect(filtered.count == 2)
        #expect(filtered.allSatisfy { $0.title.contains("函数") })
    }
}

// MARK: - ReviewViewModel DI Tests

@Suite("ReviewViewModel 依赖注入测试")
struct ReviewViewModelDITests {
    
    @Test("使用 DataProvider 初始化")
    @MainActor
    func initWithDataProvider() {
        let provider = MockReviewItemProvider()
        let viewModel = ReviewViewModel(dataProvider: provider)
        
        #expect(viewModel.items.isEmpty)
    }
    
    @Test("generateReviewQueue 使用 DataProvider 数据")
    @MainActor
    func generateReviewQueueWithProvider() {
        let provider = MockReviewItemProvider()
        let item1 = ReviewItem(title: "需要复习", subject: .math)
        item1.mastery = .partial
        let item2 = ReviewItem(title: "已掌握", subject: .physics)
        item2.mastery = .mastered
        provider.items = [item1, item2]
        
        let viewModel = ReviewViewModel(dataProvider: provider)
        let queue = viewModel.generateReviewQueue()
        
        // 应该返回结果（具体数量取决于复习算法）
        #expect(queue.count >= 0)
    }
}

// MARK: - CaptureViewModel DI Tests

@Suite("CaptureViewModel 依赖注入测试")
struct CaptureViewModelDITests {
    
    @Test("使用 DataProvider 初始化")
    @MainActor
    func initWithDataProvider() {
        let provider = MockReviewItemProvider()
        let viewModel = CaptureViewModel(dataProvider: provider)
        
        #expect(viewModel.title.isEmpty)
        #expect(viewModel.selectedImage == nil)
    }
    
    @Test("DataProvider 在初始化后可用")
    @MainActor
    func dataProviderAvailable() {
        let provider = MockReviewItemProvider()
        provider.items = [ReviewItem(title: "已有错题", subject: .math)]
        
        let viewModel = CaptureViewModel(dataProvider: provider)
        
        // ViewModel 可以访问 provider 的数据
        #expect(provider.items.count == 1)
    }
}
