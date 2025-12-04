//
//  DataProviderProtocolTests.swift
//  NotBadTests
//
//  测试 ReviewItemDataProviding 协议一致性
//

import Testing
import SwiftData
@testable import NotBad

@Suite("ReviewItemDataProviding 协议一致性测试")
struct DataProviderProtocolTests {
    
    // MARK: - 协议一致性测试
    
    @Test("MockReviewItemProvider 遵循协议")
    @MainActor
    func mockProviderConformsToProtocol() {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        #expect(provider is MockReviewItemProvider)
    }
    
    @Test("SwiftDataReviewItemProvider 遵循协议")
    @MainActor
    func swiftDataProviderConformsToProtocol() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItem.self, configurations: config)
        let context = container.mainContext
        
        let provider: any ReviewItemDataProviding = SwiftDataReviewItemProvider(modelContext: context)
        
        #expect(provider is SwiftDataReviewItemProvider)
    }
    
    // MARK: - 协议方法测试
    
    @Test("协议定义 items 属性")
    @MainActor
    func protocolDefinesItemsProperty() {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        _ = provider.items
        
        #expect(true) // 编译通过即成功
    }
    
    @Test("协议定义 refresh 方法")
    @MainActor
    func protocolDefinesRefreshMethod() {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        provider.refresh()
        
        #expect(true)
    }
    
    @Test("协议定义 save 方法")
    @MainActor
    func protocolDefinesSaveMethod() throws {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        let reviewItem = ReviewItem(title: "测试", subject: .math)
        
        try provider.save(reviewItem)
        
        #expect(true)
    }
    
    @Test("协议定义 delete 方法")
    @MainActor
    func protocolDefinesDeleteMethod() throws {
        let provider = MockReviewItemProvider()
        let reviewItem = ReviewItem(title: "测试", subject: .math)
        try provider.save(reviewItem)
        
        try (provider as any ReviewItemDataProviding).delete(reviewItem)
        
        #expect(true)
    }
    
    @Test("协议定义 search 方法")
    @MainActor
    func protocolDefinesSearchMethod() {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        let results = provider.search(query: "test")
        
        #expect(results.isEmpty)
    }
    
    @Test("协议定义 statistics 方法")
    @MainActor
    func protocolDefinesStatisticsMethod() {
        let provider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        let stats = provider.statistics()
        
        #expect(stats.totalCount == 0)
    }
    
    // MARK: - 多态性测试
    
    @Test("可以使用协议类型持有不同实现")
    @MainActor
    func canHoldDifferentImplementations() throws {
        let mockProvider: any ReviewItemDataProviding = MockReviewItemProvider()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItem.self, configurations: config)
        let swiftDataProvider: any ReviewItemDataProviding = SwiftDataReviewItemProvider(modelContext: container.mainContext)
        
        var providers: [any ReviewItemDataProviding] = []
        providers.append(mockProvider)
        providers.append(swiftDataProvider)
        
        #expect(providers.count == 2)
    }
    
    @Test("函数可以接受协议类型参数")
    @MainActor
    func functionAcceptsProtocolType() {
        func countItems(_ provider: any ReviewItemDataProviding) -> Int {
            return provider.items.count
        }
        
        let provider = MockReviewItemProvider(items: [
            ReviewItem(title: "1", subject: .math),
            ReviewItem(title: "2", subject: .physics)
        ])
        
        let count = countItems(provider)
        
        #expect(count == 2)
    }
}
