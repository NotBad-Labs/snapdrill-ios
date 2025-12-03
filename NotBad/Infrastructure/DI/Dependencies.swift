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
    
    // MARK: - Model Context
    
    /// SwiftData 模型上下文
    /// 由 App 入口设置
    var modelContext: ModelContext?
    
    // MARK: - Repository
    
    /// 错题仓库
    /// 默认使用 SwiftData 实现，测试时可替换为 Mock
    private var _reviewItemRepository: ReviewItemRepositoryProtocol?
    
    var reviewItemRepository: ReviewItemRepositoryProtocol {
        get {
            if let repo = _reviewItemRepository {
                return repo
            }
            guard let context = modelContext else {
                fatalError("ModelContext not configured. Call Dependencies.shared.configure(modelContext:) first.")
            }
            let repo = ReviewItemRepository(modelContext: context)
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
    
    // MARK: - Configuration
    
    /// 配置依赖容器
    ///
    /// - Parameter modelContext: SwiftData 模型上下文
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Reset
    
    /// 重置所有依赖到默认状态
    ///
    /// 主要用于测试清理
    func reset() {
        _reviewItemRepository = nil
        _ocrService = nil
        _pdfExportService = nil
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
