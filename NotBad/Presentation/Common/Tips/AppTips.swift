//
//  AppTips.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import TipKit

// MARK: - Capture Tips

/// 拍照录入提示
struct CapturePhotoTip: Tip {
    var title: Text {
        Text("capture_tip_photo_title")
    }
    
    var message: Text? {
        Text("capture_tip_photo_message")
    }
    
    var image: Image? {
        Image(systemName: "camera.fill")
    }
}

/// 智能识别提示
struct SmartAnalysisTip: Tip {
    var title: Text {
        Text("capture_tip_analysis_title")
    }
    
    var message: Text? {
        Text("capture_tip_analysis_message")
    }
    
    var image: Image? {
        Image(systemName: "brain.head.profile")
    }
    
    // 用户添加过图片后才显示
    @Parameter
    static var hasAddedImage: Bool = false
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasAddedImage) { $0 == true }
        ]
    }
}

// MARK: - Library Tips

/// 筛选提示
struct FilterTip: Tip {
    var title: Text {
        Text("library_tip_filter_title")
    }
    
    var message: Text? {
        Text("library_tip_filter_message")
    }
    
    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }
    
    // 题库有 5 题以上才显示
    @Parameter
    static var itemCount: Int = 0
    
    var rules: [Rule] {
        [
            #Rule(Self.$itemCount) { $0 >= 5 }
        ]
    }
}

/// 高级搜索提示
struct AdvancedSearchTip: Tip {
    var title: Text {
        Text("library_tip_search_title")
    }
    
    var message: Text? {
        Text("library_tip_search_message")
    }
    
    var image: Image? {
        Image(systemName: "magnifyingglass")
    }
    
    // 题库有 10 题以上才显示
    @Parameter
    static var itemCount: Int = 0
    
    var rules: [Rule] {
        [
            #Rule(Self.$itemCount) { $0 >= 10 }
        ]
    }
}

// MARK: - Review Tips

/// 复习手势提示
struct ReviewGestureTip: Tip {
    var title: Text {
        Text("review_tip_gesture_title")
    }
    
    var message: Text? {
        Text("review_tip_gesture_message")
    }
    
    var image: Image? {
        Image(systemName: "hand.draw")
    }
}

/// 掌握度标记提示
struct MasteryMarkTip: Tip {
    var title: Text {
        Text("review_tip_mastery_title")
    }
    
    var message: Text? {
        Text("review_tip_mastery_message")
    }
    
    var image: Image? {
        Image(systemName: "star.fill")
    }
    
    // 用户完成过一次复习后显示
    @Parameter
    static var hasCompletedReview: Bool = false
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasCompletedReview) { $0 == true }
        ]
    }
}

// MARK: - Dashboard Tips

/// 统计图表提示
struct StatisticsTip: Tip {
    var title: Text {
        Text("dashboard_tip_stats_title")
    }
    
    var message: Text? {
        Text("dashboard_tip_stats_message")
    }
    
    var image: Image? {
        Image(systemName: "chart.bar.fill")
    }
    
    // 有数据后才显示
    @Parameter
    static var hasData: Bool = false
    
    var rules: [Rule] {
        [
            #Rule(Self.$hasData) { $0 == true }
        ]
    }
}

// MARK: - Profile Tips

/// iCloud 同步提示
struct iCloudSyncTip: Tip {
    var title: Text {
        Text("profile_tip_icloud_title")
    }
    
    var message: Text? {
        Text("profile_tip_icloud_message")
    }
    
    var image: Image? {
        Image(systemName: "icloud.fill")
    }
    
    // 有 10 题以上才建议开启同步
    @Parameter
    static var itemCount: Int = 0
    
    var rules: [Rule] {
        [
            #Rule(Self.$itemCount) { $0 >= 10 }
        ]
    }
}

// MARK: - Tips Configuration

/// Tips 配置管理
enum TipsConfiguration {
    
    /// 配置 TipKit
    static func configure() {
        try? Tips.configure([
            // 每天最多显示 3 个提示
            .displayFrequency(.daily),
            // Debug 模式下立即显示所有提示
            // .displayFrequency(.immediate)
        ])
    }
    
    /// 重置所有提示状态（用于测试）
    static func resetAllTips() {
        try? Tips.resetDatastore()
    }
    
    /// 更新题库数量参数
    static func updateItemCount(_ count: Int) {
        FilterTip.itemCount = count
        AdvancedSearchTip.itemCount = count
        iCloudSyncTip.itemCount = count
        StatisticsTip.hasData = count > 0
    }
    
    /// 标记用户已添加图片
    static func markImageAdded() {
        SmartAnalysisTip.hasAddedImage = true
    }
    
    /// 标记用户已完成复习
    static func markReviewCompleted() {
        MasteryMarkTip.hasCompletedReview = true
    }
}
