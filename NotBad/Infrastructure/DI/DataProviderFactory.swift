//
//  DataProviderFactory.swift
//  NotBad
//
//  DataProvider 工厂
//  Phase 5: 简化 DataProvider 创建
//

import SwiftData

// MARK: - DataProviderFactory

/// DataProvider 工厂
///
/// 提供创建 DataProvider 的便捷方法，支持生产环境和测试环境。
///
/// ## 使用示例
///
/// ```swift
/// // 生产环境
/// let provider = DataProviderFactory.makeSwiftDataProvider(modelContainer: container)
///
/// // 测试环境
/// let mock = DataProviderFactory.makeMockProvider()
/// ```
@MainActor
enum DataProviderFactory {
    
    // MARK: - Production
    
    /// 创建 SwiftData 数据提供者
    ///
    /// - Parameter modelContainer: SwiftData 模型容器
    /// - Returns: SwiftData 实现的数据提供者
    static func makeSwiftDataProvider(modelContainer: ModelContainer) -> SwiftDataReviewItemProvider {
        SwiftDataReviewItemProvider(modelContainer: modelContainer)
    }
    
    /// 使用 AppDependencies 容器中的 ModelContainer 创建数据提供者
    ///
    /// - Returns: SwiftData 实现的数据提供者，如果工厂未配置则返回 nil
    static func makeSwiftDataProvider() -> SwiftDataReviewItemProvider? {
        guard let factory = AppDependencies.factory as? ProductionDependencyFactory else {
            return nil
        }
        return SwiftDataReviewItemProvider(modelContainer: factory.modelContainer)
    }
}

// MARK: - Environment Helper

extension DataProviderFactory {
    
    /// 为 View 创建适当的 DataProvider
    ///
    /// 如果环境中已有 DataProvider，返回 nil（使用环境中的）
    /// 否则尝试创建新的 SwiftDataProvider
    ///
    /// - Parameter environment: 环境中现有的 DataProvider
    /// - Parameter modelContainer: SwiftData 模型容器
    /// - Returns: 新创建的 DataProvider 或 nil
    static func resolveProvider(
        from environment: (any ReviewItemDataProviding)?,
        modelContainer: ModelContainer
    ) -> SwiftDataReviewItemProvider? {
        // 如果环境中已有 provider，直接使用
        if environment != nil {
            return nil
        }
        // 否则创建新的
        return makeSwiftDataProvider(modelContainer: modelContainer)
    }
}
