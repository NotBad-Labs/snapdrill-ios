//
//  MockReviewItemProviderTests.swift
//  NotBadTests
//
//  测试 MockReviewItemProvider 功能
//

import Testing
@testable import NotBad

@Suite("MockReviewItemProvider 测试")
struct MockReviewItemProviderTests {
    
    // MARK: - 初始化测试
    
    @Test("初始状态正确")
    @MainActor
    func initialState() {
        let provider = MockReviewItemProvider()
        
        #expect(provider.items.isEmpty)
        #expect(provider.isLoading == false)
        #expect(provider.lastRefreshDate == nil)
        #expect(provider.refreshCallCount == 0)
    }
    
    @Test("使用初始数据创建")
    @MainActor
    func initWithItems() {
        let items = [ReviewItem(title: "测试", subject: .math)]
        let provider = MockReviewItemProvider(items: items)
        
        #expect(provider.items.count == 1)
        #expect(provider.items.first?.title == "测试")
    }
    
    // MARK: - 刷新测试
    
    @Test("refresh 更新调用次数")
    @MainActor
    func refreshTracksCallCount() {
        let provider = MockReviewItemProvider()
        
        provider.refresh()
        provider.refresh()
        
        #expect(provider.refreshCallCount == 2)
        #expect(provider.lastRefreshDate != nil)
    }
    
    // MARK: - 保存测试
    
    @Test("save 添加新项目")
    @MainActor
    func saveAddsNewItem() throws {
        let provider = MockReviewItemProvider()
        let item = ReviewItem(title: "新错题", subject: .physics)
        
        try provider.save(item)
        
        #expect(provider.items.count == 1)
        #expect(provider.saveCallCount == 1)
        #expect(provider.lastSavedItem?.title == "新错题")
    }
    
    @Test("save 更新已存在项目")
    @MainActor
    func saveUpdatesExistingItem() throws {
        let provider = MockReviewItemProvider()
        let item = ReviewItem(title: "原标题", subject: .math)
        try provider.save(item)
        
        item.title = "新标题"
        try provider.save(item)
        
        #expect(provider.items.count == 1)
        #expect(provider.items.first?.title == "新标题")
        #expect(provider.saveCallCount == 2)
    }
    
    @Test("save 可抛出错误")
    @MainActor
    func saveThrowsError() throws {
        let provider = MockReviewItemProvider()
        provider.shouldThrowOnSave = true
        let item = ReviewItem(title: "错题", subject: .math)
        
        #expect(throws: MockError.self) {
            try provider.save(item)
        }
    }
    
    // MARK: - 删除测试
    
    @Test("delete 删除项目")
    @MainActor
    func deleteRemovesItem() throws {
        let item = ReviewItem(title: "待删除", subject: .chinese)
        let provider = MockReviewItemProvider(items: [item])
        
        try provider.delete(item)
        
        #expect(provider.items.isEmpty)
        #expect(provider.deleteCallCount == 1)
        #expect(provider.lastDeletedItem?.title == "待删除")
    }
    
    @Test("delete 可抛出错误")
    @MainActor
    func deleteThrowsError() throws {
        let provider = MockReviewItemProvider()
        provider.shouldThrowOnDelete = true
        let item = ReviewItem(title: "错题", subject: .math)
        
        #expect(throws: MockError.self) {
            try provider.delete(item)
        }
    }
    
    // MARK: - 搜索测试
    
    @Test("search 按标题搜索")
    @MainActor
    func searchByTitle() {
        let provider = MockReviewItemProvider(items: [
            ReviewItem(title: "二次函数", subject: .math),
            ReviewItem(title: "一次函数", subject: .math),
            ReviewItem(title: "古诗词", subject: .chinese)
        ])
        
        let results = provider.search(query: "函数")
        
        #expect(results.count == 2)
        #expect(provider.searchCallCount == 1)
        #expect(provider.lastSearchQuery == "函数")
    }
    
    @Test("search 返回自定义结果")
    @MainActor
    func searchReturnsCustomResults() {
        let provider = MockReviewItemProvider()
        let customResults = [ReviewItem(title: "自定义", subject: .math)]
        provider.searchResults = customResults
        
        let results = provider.search(query: "任意")
        
        #expect(results.count == 1)
        #expect(results.first?.title == "自定义")
    }
    
    // MARK: - fetchForReview 测试
    
    @Test("fetchForReview 返回需要复习的项目")
    @MainActor
    func fetchForReviewReturnsItems() {
        let item = ReviewItem(title: "需复习", subject: .math)
        let provider = MockReviewItemProvider(items: [item])
        
        _ = provider.fetchForReview()
        
        #expect(provider.fetchForReviewCallCount == 1)
    }
    
    @Test("fetchForReview 返回自定义结果")
    @MainActor
    func fetchForReviewReturnsCustomResults() {
        let provider = MockReviewItemProvider()
        let customItems = [ReviewItem(title: "自定义复习", subject: .physics)]
        provider.reviewItems = customItems
        
        let results = provider.fetchForReview()
        
        #expect(results.count == 1)
        #expect(results.first?.title == "自定义复习")
    }
    
    // MARK: - 统计测试
    
    @Test("statistics 返回统计数据")
    @MainActor
    func statisticsReturnsData() {
        let item1 = ReviewItem(title: "错题1", subject: .math)
        item1.mastery = .mastered
        let item2 = ReviewItem(title: "错题2", subject: .physics)
        item2.mastery = .none
        let provider = MockReviewItemProvider(items: [item1, item2])
        
        let stats = provider.statistics()
        
        #expect(stats.totalCount == 2)
    }
    
    // MARK: - 重置测试
    
    @Test("resetCallTracking 清除调用记录")
    @MainActor
    func resetCallTrackingClearsRecords() throws {
        let provider = MockReviewItemProvider()
        try provider.save(ReviewItem(title: "测试", subject: .math))
        _ = provider.search(query: "test")
        provider.refresh()
        
        provider.resetCallTracking()
        
        #expect(provider.saveCallCount == 0)
        #expect(provider.searchCallCount == 0)
        #expect(provider.refreshCallCount == 0)
        #expect(provider.lastSearchQuery == nil)
    }
    
    @Test("reset 清除所有状态")
    @MainActor
    func resetClearsAllState() throws {
        let provider = MockReviewItemProvider()
        try provider.save(ReviewItem(title: "测试", subject: .math))
        provider.shouldThrowOnSave = true
        
        provider.reset()
        
        #expect(provider.items.isEmpty)
        #expect(provider.saveCallCount == 0)
        #expect(provider.shouldThrowOnSave == false)
    }
}
