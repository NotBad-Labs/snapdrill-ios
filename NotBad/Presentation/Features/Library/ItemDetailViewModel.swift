//
//  ItemDetailViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  CQRS 架构：Command 层 - 处理写操作
//

import SwiftUI
import OSLog

// MARK: - ItemDetailViewModel

/// 错题详情 ViewModel
///
/// 负责处理错题详情页的业务逻辑和写操作。
/// 遵循 CQRS 原则：View 使用 `@Bindable` 读取数据，
/// 所有修改操作通过 ViewModel 执行。
///
/// ## 职责
///
/// - 删除错题
/// - 保存修改
/// - 业务逻辑验证
///
/// ## 依赖注入
///
/// ```swift
/// @State private var viewModel = ItemDetailViewModel()
/// viewModel.configure(with: factory)
/// ```
@Observable
@MainActor
final class ItemDetailViewModel {
    
    // MARK: - Dependencies
    
    /// 删除用例
    private var deleteUseCase: DeleteReviewItemUseCaseProtocol?
    
    /// 更新用例
    private var updateUseCase: UpdateReviewItemUseCaseProtocol?
    
    /// 分析服务
    private let analyticsService: any AnalyticsServiceProtocol
    
    // MARK: - Initialization
    
    init(analyticsService: any AnalyticsServiceProtocol = LocalAnalyticsService.shared) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Configuration
    
    /// 配置 ViewModel
    ///
    /// - Parameter factory: 依赖工厂
    func configure(with factory: DependencyFactory) {
        self.deleteUseCase = factory.makeDeleteReviewItemUseCase()
        self.updateUseCase = factory.makeUpdateReviewItemUseCase()
    }
    
    // MARK: - Commands
    
    /// 删除错题
    ///
    /// - Parameter reviewItem: 要删除的错题
    /// - Returns: 删除是否成功
    @discardableResult
    func delete(_ reviewItem: ReviewItem) -> Bool {
        guard let deleteUseCase else {
            Logger.data.error("ItemDetailViewModel: deleteUseCase 未配置")
            return false
        }
        
        // 记录分析事件
        analyticsService.track(AnalyticsEvent(
            name: AnalyticsEventName.itemDeleted,
            parameters: [
                "subject": reviewItem.subject.rawValue,
                "mastery": String(reviewItem.mastery.rawValue)
            ]
        ))
        
        Task {
            do {
                try await deleteUseCase.execute(itemId: reviewItem.id)
                Logger.data.info("删除错题成功: \(reviewItem.title)")
                
                // 发送通知
                NotificationCenter.default.post(name: .reviewItemDeleted, object: reviewItem.id)
            } catch {
                Logger.data.error("删除错题失败: \(error)")
            }
        }
        
        return true
    }
    
    /// 保存修改
    ///
    /// - Parameter reviewItem: 要保存的错题
    /// - Returns: 保存是否成功
    @discardableResult
    func save(_ reviewItem: ReviewItem) -> Bool {
        guard let updateUseCase else {
            Logger.data.error("ItemDetailViewModel: updateUseCase 未配置")
            return false
        }
        
        Task {
            do {
                let updates = ReviewItemUpdates(
                    title: reviewItem.title,
                    imageData: reviewItem.imageData,
                    subject: reviewItem.subject,
                    grade: reviewItem.grade,
                    difficulty: reviewItem.difficulty,
                    errorType: reviewItem.errorType,
                    knowledgePoints: reviewItem.knowledgePoints.items,
                    note: reviewItem.note,
                    mastery: reviewItem.mastery
                )
                
                try await updateUseCase.execute(itemId: reviewItem.id, updates: updates)
                Logger.data.debug("保存错题成功: \(reviewItem.title)")
                
                // 发送通知
                NotificationCenter.default.post(name: .reviewItemUpdated, object: reviewItem)
            } catch {
                Logger.data.error("保存错题失败: \(error)")
            }
        }
        
        return true
    }
}
