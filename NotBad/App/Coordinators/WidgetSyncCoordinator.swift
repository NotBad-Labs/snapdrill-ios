//
//  WidgetSyncCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import SwiftData
import OSLog

// MARK: - WidgetSyncCoordinator

/// Widget 数据同步协调器
///
/// 负责管理 Widget 与主应用之间的数据同步，包括：
/// - 初始同步
/// - 数据变更后的增量同步
/// - 防抖处理（避免批量操作时高频同步）
@MainActor
@Observable
final class WidgetSyncCoordinator {
    
    // MARK: - State
    
    /// 是否正在同步
    private(set) var isSyncing: Bool = false
    
    /// 防抖任务
    private var debounceTask: Task<Void, Never>?
    
    /// 防抖延迟（秒）
    private let debounceDelay: TimeInterval = 1.5
    
    // MARK: - Dependencies
    
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Actions
    
    /// 立即同步数据到 Widget
    func sync() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        defer { isSyncing = false }
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<ReviewItemModel>()
        
        do {
            let models = try context.fetch(descriptor)
            let items = models.map { ReviewItemMapper.toEntity(from: $0) }
            items.syncToWidget()
            Logger.widget.debug("✅ Widget 数据同步完成，共 \(items.count) 条")
        } catch {
            Logger.widget.error("❌ Widget 数据同步失败: \(error.localizedDescription)")
        }
    }
    
    /// 调度同步（带防抖）
    ///
    /// 当用户批量删除或修改错题时，会触发多次通知。
    /// 使用防抖机制避免 Widget 数据疯狂同步，减少 CPU 和 I/O 压力。
    func scheduleSync() {
        // 取消之前的防抖任务
        debounceTask?.cancel()
        
        // 延迟执行同步
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(debounceDelay))
            
            guard !Task.isCancelled else { return }
            
            await sync()
        }
    }
    
    /// 取消待执行的同步任务
    func cancelPendingSync() {
        debounceTask?.cancel()
        debounceTask = nil
    }
}
