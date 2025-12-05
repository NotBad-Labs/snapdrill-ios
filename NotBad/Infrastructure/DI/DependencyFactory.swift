//
//  DependencyFactory.swift
//  NotBad
//
//  依赖工厂协议 - 支持生产/测试环境切换
//

import Foundation
import SwiftData

// MARK: - DependencyFactory Protocol

/// 依赖工厂协议
///
/// 定义创建所有依赖的统一接口，支持：
/// - 生产环境使用真实实现
/// - 测试环境使用 Mock 实现
///
/// ## 使用示例
///
/// ```swift
/// // 生产环境
/// let factory = ProductionDependencyFactory(modelContainer: container)
/// let viewModel = factory.makeLibraryViewModel()
///
/// // 测试环境
/// let factory = TestDependencyFactory()
/// let viewModel = factory.makeLibraryViewModel()
/// ```
@MainActor
protocol DependencyFactory: Sendable {
    
    // MARK: - Repositories
    
    /// 创建错题仓库
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol
    
    // MARK: - Use Cases - Review
    
    /// 创建开始复习会话用例
    func makeStartReviewSessionUseCase() -> StartReviewSessionUseCaseProtocol
    
    /// 创建记录复习结果用例
    func makeRecordReviewResultUseCase() -> RecordReviewResultUseCaseProtocol
    
    /// 创建完成复习会话用例
    func makeCompleteReviewSessionUseCase() -> CompleteReviewSessionUseCaseProtocol
    
    // MARK: - Use Cases - Library
    
    /// 创建创建错题用例
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCaseProtocol
    
    /// 创建获取错题用例
    func makeFetchReviewItemsUseCase() -> FetchReviewItemsUseCaseProtocol
    
    // MARK: - Use Cases - Statistics
    
    /// 创建获取统计数据用例
    func makeGetStatisticsUseCase() -> GetStatisticsUseCaseProtocol
    
    // MARK: - Services
    
    /// 创建 OCR 服务
    func makeOCRService() -> any OCRServiceProtocol
    
    /// 创建分析服务
    func makeAnalyticsService() -> any AnalyticsServiceProtocol
}

// MARK: - ProductionDependencyFactory

/// 生产环境依赖工厂
///
/// 创建真实的依赖实现，用于正式运行环境。
@MainActor
final class ProductionDependencyFactory: DependencyFactory {
    
    // MARK: - Properties
    
    private let modelContainer: ModelContainer
    
    /// 缓存的 Repository（避免重复创建）
    private lazy var reviewItemRepository: ReviewItemRepositoryProtocol = {
        ReviewItemRepository(modelContainer: modelContainer)
    }()
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Repositories
    
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol {
        return reviewItemRepository
    }
    
    // MARK: - Use Cases - Review
    
    func makeStartReviewSessionUseCase() -> StartReviewSessionUseCaseProtocol {
        StartReviewSessionUseCase(repository: reviewItemRepository)
    }
    
    func makeRecordReviewResultUseCase() -> RecordReviewResultUseCaseProtocol {
        fatalError("RecordReviewResultUseCase not implemented yet")
    }
    
    func makeCompleteReviewSessionUseCase() -> CompleteReviewSessionUseCaseProtocol {
        CompleteReviewSessionUseCase(repository: reviewItemRepository)
    }
    
    // MARK: - Use Cases - Library
    
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCaseProtocol {
        fatalError("CreateReviewItemUseCase not implemented yet")
    }
    
    func makeFetchReviewItemsUseCase() -> FetchReviewItemsUseCaseProtocol {
        FetchReviewItemsUseCase(repository: reviewItemRepository)
    }
    
    // MARK: - Use Cases - Statistics
    
    func makeGetStatisticsUseCase() -> GetStatisticsUseCaseProtocol {
        fatalError("GetStatisticsUseCase not implemented yet")
    }
    
    // MARK: - Services
    
    func makeOCRService() -> any OCRServiceProtocol {
        OCRService.shared
    }
    
    func makeAnalyticsService() -> any AnalyticsServiceProtocol {
        LocalAnalyticsService.shared
    }
}

// MARK: - AppDependencies

/// 应用依赖容器
///
/// 管理应用级别的依赖工厂实例。
/// 
/// ## 使用示例
///
/// ```swift
/// // App 入口配置
/// AppDependencies.configure(factory: ProductionDependencyFactory(modelContainer: container))
///
/// // 获取依赖
/// let useCase = AppDependencies.factory.makeStartReviewSessionUseCase()
/// ```
@MainActor
enum AppDependencies {
    
    /// 当前依赖工厂
    private(set) static var factory: DependencyFactory!
    
    /// 配置依赖工厂
    ///
    /// - Parameter factory: 依赖工厂实例
    static func configure(factory: DependencyFactory) {
        self.factory = factory
    }
    
    /// 使用 ModelContainer 配置生产环境工厂
    ///
    /// - Parameter modelContainer: SwiftData 模型容器
    static func configure(modelContainer: ModelContainer) {
        self.factory = ProductionDependencyFactory(modelContainer: modelContainer)
    }
    
    /// 重置（用于测试）
    static func reset() {
        factory = nil
    }
}

// MARK: - Environment Key (Optional)

import SwiftUI

/// 依赖工厂环境键
private struct DependencyFactoryKey: EnvironmentKey {
    nonisolated(unsafe) static let defaultValue: DependencyFactory? = nil
}

extension EnvironmentValues {
    /// 依赖工厂
    var dependencyFactory: DependencyFactory? {
        get { self[DependencyFactoryKey.self] }
        set { self[DependencyFactoryKey.self] = newValue }
    }
}

// MARK: - View Modifier

/// 便捷的依赖注入修饰符
struct WithDependencies: ViewModifier {
    let factory: DependencyFactory
    
    func body(content: Content) -> some View {
        content.environment(\.dependencyFactory, factory)
    }
}

extension View {
    /// 注入依赖工厂
    func withDependencies(_ factory: DependencyFactory) -> some View {
        modifier(WithDependencies(factory: factory))
    }
}

// MARK: - ViewModel Factory Extension

extension DependencyFactory {
    
    /// 创建 ReviewViewModel（带 Use Cases 注入）
    func makeReviewViewModel() -> ReviewViewModel {
        ReviewViewModel(
            startSessionUseCase: makeStartReviewSessionUseCase(),
            recordResultUseCase: makeRecordReviewResultUseCase(),
            completeSessionUseCase: makeCompleteReviewSessionUseCase()
        )
    }
}
