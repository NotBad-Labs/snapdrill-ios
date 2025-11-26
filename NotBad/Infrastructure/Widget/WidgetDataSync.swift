//
//  WidgetDataSync.swift
//  NotBad
//
//  同步数据到 Widget
//

import Foundation
import WidgetKit

/// Widget 数据同步服务
@MainActor
final class WidgetDataSync {
    
    // MARK: - Singleton
    
    static let shared = WidgetDataSync()
    
    private init() {}
    
    // MARK: - App Group
    
    private let appGroupIdentifier = "group.com.notbad.app"
    
    private var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let pendingReviewCount = "pendingReviewCount"
        static let overdueCount = "overdueCount"
        static let masteryRate = "masteryRate"
        static let recentSubjects = "recentSubjects"
        static let lastUpdated = "lastUpdated"
    }
    
    // MARK: - Sync Methods
    
    /// 同步复习统计数据
    func syncReviewStats(
        pendingCount: Int,
        overdueCount: Int,
        masteryRate: Double,
        recentSubjects: [String]
    ) {
        guard let defaults = sharedDefaults else {
            #if DEBUG
            print("[WidgetDataSync] Failed to access shared UserDefaults")
            #endif
            return
        }
        
        defaults.set(pendingCount, forKey: Keys.pendingReviewCount)
        defaults.set(overdueCount, forKey: Keys.overdueCount)
        defaults.set(masteryRate, forKey: Keys.masteryRate)
        defaults.set(Array(recentSubjects.prefix(5)), forKey: Keys.recentSubjects)
        defaults.set(Date(), forKey: Keys.lastUpdated)
        
        // 刷新 Widget
        reloadWidgets()
        
        #if DEBUG
        print("[WidgetDataSync] Synced stats: pending=\(pendingCount), overdue=\(overdueCount), mastery=\(masteryRate)")
        #endif
    }
    
    /// 更新待复习数量
    func updatePendingCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: Keys.pendingReviewCount)
        reloadWidgets()
    }
    
    /// 更新逾期数量
    func updateOverdueCount(_ count: Int) {
        sharedDefaults?.set(count, forKey: Keys.overdueCount)
        reloadWidgets()
    }
    
    /// 更新掌握率
    func updateMasteryRate(_ rate: Double) {
        sharedDefaults?.set(rate, forKey: Keys.masteryRate)
        reloadWidgets()
    }
    
    /// 更新最近学科
    func updateRecentSubjects(_ subjects: [String]) {
        sharedDefaults?.set(Array(subjects.prefix(5)), forKey: Keys.recentSubjects)
        reloadWidgets()
    }
    
    // MARK: - Widget Reload
    
    /// 刷新所有 Widget
    func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// 刷新特定 Widget
    func reloadWidget(kind: String = "NotBadWidget") {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
    }
}

// MARK: - ReviewItem Collection Extension

extension Array where Element == ReviewItem {
    
    /// 同步数据到 Widget
    @MainActor
    func syncToWidget() {
        // 计算待复习数量
        let pendingCount = self.filter { $0.needsReview }.count
        
        // 计算逾期数量
        let overdueCount = self.filter { $0.isOverdue }.count
        
        // 计算掌握率
        let totalItems = self.count
        let masteredCount = self.filter { $0.isMastered }.count
        let masteryRate = totalItems > 0 ? Double(masteredCount) / Double(totalItems) : 0
        
        // 获取最近学科
        var subjectSet = Set<String>()
        for item in self {
            subjectSet.insert(item.subject.displayName)
        }
        var recentSubjects: [String] = []
        for (index, subject) in subjectSet.enumerated() {
            if index >= 5 { break }
            recentSubjects.append(subject)
        }
        
        WidgetDataSync.shared.syncReviewStats(
            pendingCount: pendingCount,
            overdueCount: overdueCount,
            masteryRate: masteryRate,
            recentSubjects: recentSubjects
        )
    }
}
