//
//  AnalyticsService.swift
//  NotBadFeatures
//
//  Created by NotBad Architect on 2026/01/01.
//

import Foundation
import SwiftData
import NotBadData

/// 轻量级本地数据统计服务
///
/// 负责统计用户的学习行为数据，如今日录入题目数、复习情况等。
/// 不涉及第三方埋点，仅基于本地 SwiftData 数据进行聚合。
public enum AnalyticsService {
    
    /// 统计今日新录入的题目数量
    @MainActor
    public static func countItemsCreatedToday(in context: ModelContext) -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        
        // 谓词：createdAt >= 今天0点
        let predicate = #Predicate<ReviewItemModel> { item in
            item.createdAt >= startOfDay
        }
        
        let descriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        
        do {
            // 只需要计数，不需要取出所有对象
            // 注意：SwiftData 的 fetchCount 目前在某些版本可能不如 fetch 高效，但语义更准确。
            // 为了保险起见，在大数据量下应使用 fetchCount。
            return try context.fetchCount(descriptor)
        } catch {
            print("Failed to fetch daily stats: \(error)")
            return 0
        }
    }
}
