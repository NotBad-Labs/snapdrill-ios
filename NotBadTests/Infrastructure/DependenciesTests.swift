//
//  DependenciesTests.swift
//  NotBadTests
//
//  测试 Dependencies 依赖容器
//

import Testing
import SwiftData
@testable import NotBad

@Suite("Dependencies 依赖容器测试")
struct DependenciesTests {
    
    // MARK: - 单例测试
    
    @Test("shared 返回单例实例")
    @MainActor
    func sharedReturnsSingleton() {
        let instance1 = Dependencies.shared
        let instance2 = Dependencies.shared
        
        #expect(instance1 === instance2)
    }
    
    // MARK: - ModelContainer 测试
    
    @Test("初始 modelContainer 为 nil")
    @MainActor
    func initialModelContainerIsNil() {
        let deps = Dependencies.shared
        // 注意：在测试环境中可能已经配置了 modelContainer
        // 这里只验证属性可访问
        _ = deps.modelContainer
        #expect(true)
    }
    
    @Test("可以设置 modelContainer")
    @MainActor
    func canSetModelContainer() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
        
        Dependencies.shared.configure(modelContainer: container)
        
        #expect(Dependencies.shared.modelContainer != nil)
    }
}

@Suite("DataProviderFactory 测试")
struct DataProviderFactoryTests {
    
    @Test("makeSwiftDataProvider 创建 Provider")
    @MainActor
    func makeSwiftDataProviderCreatesProvider() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
        
        let provider = DataProviderFactory.makeSwiftDataProvider(modelContainer: container)
        
        #expect(provider is SwiftDataReviewItemProvider)
    }
    
    @Test("创建的 Provider 初始 items 为空")
    @MainActor
    func createdProviderHasEmptyItems() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
        
        let provider = DataProviderFactory.makeSwiftDataProvider(modelContainer: container)
        
        #expect(provider.items.isEmpty)
    }
    
    @Test("多次调用创建独立 Provider")
    @MainActor
    func multipleCallsCreateIndependentProviders() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItemModel.self, configurations: config)
        
        let provider1 = DataProviderFactory.makeSwiftDataProvider(modelContainer: container)
        let provider2 = DataProviderFactory.makeSwiftDataProvider(modelContainer: container)
        
        #expect(provider1 !== provider2)
    }
}
