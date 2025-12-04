//
//  ItemDetailViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  CQRS 架构：Command 层 - 处理写操作
//

import SwiftUI
import SwiftData
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
/// viewModel.configure(with: modelContext)
/// ```
@Observable
@MainActor
final class ItemDetailViewModel {
    
    // MARK: - Dependencies
    
    /// 数据上下文
    private var modelContext: ModelContext?
    
    /// 分析服务
    private let analyticsService: any AnalyticsServiceProtocol
    
    // MARK: - Initialization
    
    init(analyticsService: any AnalyticsServiceProtocol = LocalAnalyticsService.shared) {
        self.analyticsService = analyticsService
    }
    
    // MARK: - Configuration
    
    /// 配置 ViewModel
    ///
    /// - Parameter context: SwiftData 模型上下文
    func configure(with context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Commands
    
    /// 删除错题
    ///
    /// - Parameter item: 要删除的错题
    /// - Returns: 删除是否成功
    @discardableResult
    func delete(_ item: ReviewItem) -> Bool {
        guard let modelContext else {
            Logger.data.error("ItemDetailViewModel: modelContext 未配置")
            return false
        }
        
        // 记录分析事件
        analyticsService.track(AnalyticsEvent(
            name: AnalyticsEventName.itemDeleted,
            parameters: [
                "subject": item.subject.rawValue,
                "mastery": String(item.mastery.rawValue)
            ]
        ))
        
        // 执行删除
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            Logger.data.info("删除错题成功: \(item.title)")
            
            // 发送通知
            NotificationCenter.default.post(name: .reviewItemDeleted, object: item.id)
            
            return true
        } catch {
            Logger.data.error("删除错题失败: \(error)")
            return false
        }
    }
    
    /// 保存修改
    ///
    /// - Parameter item: 要保存的错题
    /// - Returns: 保存是否成功
    @discardableResult
    func save(_ item: ReviewItem) -> Bool {
        guard let modelContext else {
            Logger.data.error("ItemDetailViewModel: modelContext 未配置")
            return false
        }
        
        // 更新时间戳
        item.updatedAt = Date()
        
        do {
            try modelContext.save()
            Logger.data.debug("保存错题成功: \(item.title)")
            
            // 发送通知
            NotificationCenter.default.post(name: .reviewItemUpdated, object: item)
            
            return true
        } catch {
            Logger.data.error("保存错题失败: \(error)")
            return false
        }
    }
}
