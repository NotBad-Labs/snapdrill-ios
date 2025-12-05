//
//  Dependencies.swift
//  NotBad
//
//  依赖容器 - 管理应用的依赖注入
//

import Foundation
import SwiftData

// MARK: - Dependencies

/// 依赖容器
///
/// 提供应用级别的依赖管理，支持在生产环境和测试环境中切换实现。
///
/// ## 使用示例
///
/// ```swift
/// // 生产环境
/// let repository = Dependencies.shared.reviewItemRepository
///
/// // 测试环境
/// Dependencies.shared.reviewItemRepository = MockReviewItemRepository()
/// ```
///
/// - Note: 使用单例模式，通过 `.shared` 访问
/// - Important: 测试完成后记得重置依赖
@MainActor
final class Dependencies {
    
    // MARK: - Singleton
    
    /// 共享实例
    static let shared = Dependencies()
    
    // MARK: - Private Init
    
    private init() {}
    
    // MARK: - Model Container
    
    /// SwiftData 模型容器
    /// 由 App 入口设置
    var modelContainer: ModelContainer?
    
    /// SwiftData 模型上下文（便捷访问）
    var modelContext: ModelContext? {
        modelContainer?.mainContext
    }
    
    // MARK: - Repository
    
    /// 错题仓库
    /// 默认使用 SwiftData 实现，测试时可替换为 Mock
    private var _reviewItemRepository: ReviewItemRepositoryProtocol?
    
    var reviewItemRepository: ReviewItemRepositoryProtocol {
        get {
            if let repo = _reviewItemRepository {
                return repo
            }
            guard let container = modelContainer else {
                fatalError("ModelContainer not configured. Call Dependencies.shared.configure(modelContainer:) first.")
            }
            let repo = ReviewItemRepository(modelContainer: container)
            _reviewItemRepository = repo
            return repo
        }
        set {
            _reviewItemRepository = newValue
        }
    }
    
    // MARK: - Services
    
    /// OCR 服务
    private var _ocrService: (any OCRServiceProtocol)?
    
    var ocrService: any OCRServiceProtocol {
        get {
            if let service = _ocrService {
                return service
            }
            let service = OCRService.shared
            _ocrService = service
            return service
        }
        set {
            _ocrService = newValue
        }
    }
    
    /// PDF 导出服务
    private var _pdfExportService: (any PDFExportServiceProtocol)?
    
    var pdfExportService: any PDFExportServiceProtocol {
        get {
            if let service = _pdfExportService {
                return service
            }
            let service = PDFExportService.shared
            _pdfExportService = service
            return service
        }
        set {
            _pdfExportService = newValue
        }
    }
    
    /// 埋点服务
    private var _analyticsService: (any AnalyticsServiceProtocol)?
    
    var analyticsService: any AnalyticsServiceProtocol {
        get {
            if let service = _analyticsService {
                return service
            }
            let service = LocalAnalyticsService.shared
            _analyticsService = service
            return service
        }
        set {
            _analyticsService = newValue
        }
    }
    
    // MARK: - Configuration
    
    /// 配置依赖容器
    ///
    /// - Parameter modelContainer: SwiftData 模型容器
    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Reset
    
    /// 重置所有依赖到默认状态
    ///
    /// 主要用于测试清理
    func reset() {
        _reviewItemRepository = nil
        _ocrService = nil
        _pdfExportService = nil
        _analyticsService = nil
    }
}

// MARK: - Convenience Extensions

extension Dependencies {
    
    /// 使用 Mock Repository 进行测试
    ///
    /// - Parameter mock: Mock 仓库实例
    /// - Returns: 返回 mock 以便链式调用
    @discardableResult
    func useMockRepository(_ mock: ReviewItemRepositoryProtocol) -> ReviewItemRepositoryProtocol {
        self.reviewItemRepository = mock
        return mock
    }
}
