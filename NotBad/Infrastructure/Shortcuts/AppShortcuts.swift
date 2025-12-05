//
//  AppShortcuts.swift
//  NotBad
//
//  Siri Shortcuts 支持
//

import AppIntents
import SwiftUI

// MARK: - App Shortcuts Provider

/// 应用快捷指令提供者
///
/// 定义可在 Shortcuts 应用中使用的快捷指令。
struct NotBadShortcuts: AppShortcutsProvider {
    
    /// 应用快捷指令
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddReviewItemIntent(),
            phrases: [
                "Add error in \(.applicationName)",
                "添加错题到 \(.applicationName)",
                "Record mistake in \(.applicationName)",
                "记录错题到 \(.applicationName)"
            ],
            shortTitle: "shortcut_add_item_title",
            systemImageName: "plus.circle.fill"
        )
        
        AppShortcut(
            intent: StartReviewIntent(),
            phrases: [
                "Start review in \(.applicationName)",
                "开始复习 \(.applicationName)",
                "Review mistakes in \(.applicationName)",
                "复习错题 \(.applicationName)"
            ],
            shortTitle: "shortcut_start_review_title",
            systemImageName: "book.circle.fill"
        )
        
        AppShortcut(
            intent: GetTodayStatsIntent(),
            phrases: [
                "Show today's stats in \(.applicationName)",
                "显示今日统计 \(.applicationName)",
                "How many mistakes today \(.applicationName)"
            ],
            shortTitle: "shortcut_today_stats_title",
            systemImageName: "chart.bar.fill"
        )
    }
}

// MARK: - Add Review Item Intent

/// 添加错题快捷指令
///
/// 打开应用并跳转到录入页面。
struct AddReviewItemIntent: AppIntent {
    
    static let title: LocalizedStringResource = "shortcut_add_item_intent_title"
    static let description: IntentDescription = "shortcut_add_item_intent_description"
    static let openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // 切换到录入页面
        await MainActor.run {
            NavigationRouter.shared.selectedTab = .capture
        }
        return .result()
    }
}

// MARK: - Start Review Intent

/// 开始复习快捷指令
///
/// 打开应用并跳转到复习页面。
struct StartReviewIntent: AppIntent {
    
    static let title: LocalizedStringResource = "shortcut_start_review_intent_title"
    static let description: IntentDescription = "shortcut_start_review_intent_description"
    static let openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // 切换到复习页面
        await MainActor.run {
            NavigationRouter.shared.selectedTab = .review
        }
        return .result()
    }
}

// MARK: - Get Today Stats Intent

/// 获取今日统计快捷指令
///
/// 返回今日的复习统计信息。
struct GetTodayStatsIntent: AppIntent {
    
    static let title: LocalizedStringResource = "shortcut_today_stats_intent_title"
    static let description: IntentDescription = "shortcut_today_stats_intent_description"
    
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // 从 UserDefaults 获取 Widget 共享数据
        let sharedDefaults = UserDefaults(suiteName: "group.com.notbad.app")
        
        let totalCount = sharedDefaults?.integer(forKey: "widget_total_count") ?? 0
        let masteredCount = sharedDefaults?.integer(forKey: "widget_mastered_count") ?? 0
        let pendingCount = sharedDefaults?.integer(forKey: "widget_pending_count") ?? 0
        let todayReviewedCount = sharedDefaults?.integer(forKey: "widget_today_reviewed") ?? 0
        
        let stats = String(format: String(localized: "shortcut_stats_result"),
                          totalCount, masteredCount, pendingCount, todayReviewedCount)
        
        return .result(value: stats)
    }
}
