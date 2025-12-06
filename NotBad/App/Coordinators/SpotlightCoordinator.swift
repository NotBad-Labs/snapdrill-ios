//
//  SpotlightCoordinator.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import Foundation
import CoreSpotlight
import OSLog

// MARK: - SpotlightCoordinator

/// Spotlight 搜索结果导航协调器
///
/// 负责处理用户从 Spotlight 搜索结果点击进入应用的导航。
@MainActor
@Observable
final class SpotlightCoordinator {
    
    // MARK: - State
    
    /// 待导航的错题 ID
    var pendingItemId: UUID?
    
    // MARK: - Dependencies
    
    private let tabCoordinator: TabCoordinator
    
    // MARK: - Initialization
    
    init(tabCoordinator: TabCoordinator) {
        self.tabCoordinator = tabCoordinator
    }
    
    // MARK: - Actions
    
    /// 处理 Spotlight 搜索结果点击
    ///
    /// - Parameter activity: NSUserActivity
    /// - Returns: 是否成功处理
    @discardableResult
    func handle(_ activity: NSUserActivity) -> Bool {
        guard activity.activityType == CSSearchableItemActionType else {
            return false
        }
        
        guard let itemId = SpotlightIndexService.handleSpotlightActivity(activity) else {
            Logger.app.warning("⚠️ Spotlight activity 无法解析 itemId")
            return false
        }
        
        pendingItemId = itemId
        navigateToItem(id: itemId)
        
        Logger.app.debug("✅ Spotlight 导航: item \(itemId)")
        return true
    }
    
    /// 导航到指定错题
    func navigateToItem(id: UUID) {
        // 使用 TabCoordinator 导航到错题详情
        tabCoordinator.navigateToItemDetail(itemId: id)
        
        // 清除待导航状态
        pendingItemId = nil
    }
}
