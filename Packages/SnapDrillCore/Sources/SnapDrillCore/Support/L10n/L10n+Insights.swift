//
//  L10n+Insights.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 首页分片。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Dashboard

    public enum Dashboard {
        public static let title = NSLocalizedString("dashboard.title", value: "首页", comment: "首页 Tab 标题")

        // 空状态
        public static let emptyTitle = NSLocalizedString("dashboard.empty_title", value: "还没有任何资料", comment: "空状态标题")
        public static let emptyDescription = NSLocalizedString("dashboard.empty_description", value: "拍摄或导入一条资料，建立你的资料库", comment: "空状态描述")
        public static let goCapture = NSLocalizedString("dashboard.go_capture", value: "开始采集", comment: "去采集按钮")

        // Bento 卡片
        public static let smartScan = NSLocalizedString("dashboard.smart_scan", value: "快速采集", comment: "快速采集卡片标题")
        public static let addNew = NSLocalizedString("dashboard.add_new", value: "添加资料", comment: "添加资料副标题")
        public static let browseLibrary = NSLocalizedString("dashboard.browse_library", value: "资料库", comment: "资料库卡片标题")
        public static let manageKnowledge = NSLocalizedString("dashboard.manage_knowledge", value: "浏览与整理", comment: "资料库副标题")
        public static let categoryManage = NSLocalizedString("dashboard.category_manage", value: "科目管理", comment: "科目管理卡片标题")
        public static let customize = NSLocalizedString("dashboard.customize", value: "自定义", comment: "自定义副标题")

        // 本地资料概览
        public static let todayAdded = NSLocalizedString("dashboard.today_added", value: "今日新增", comment: "今日新增")
        public static let uncategorized = NSLocalizedString("dashboard.uncategorized", value: "未分类", comment: "统计中无分类维度值的资料分组")

        // 草稿恢复
        public static let draftAlertTitle = NSLocalizedString("dashboard.draft_alert_title", value: "恢复未完成的采集？", comment: "Dashboard 草稿恢复弹窗")
        public static let draftStartNew = NSLocalizedString("dashboard.draft_start_new", value: "开始新的", comment: "开始新的按钮")
        public static let draftRestore = NSLocalizedString("dashboard.draft_restore", value: "恢复", comment: "恢复按钮")
        public static let draftAlertMessage = NSLocalizedString("dashboard.draft_alert_message", value: "你有上次未保存的采集内容，是否继续编辑？", comment: "Dashboard 草稿恢复提示")
        public static func draftAlertMessage(category: String, timeAgo: String) -> String {
            String(
                format: NSLocalizedString(
                    "dashboard.draft_alert_message_with_category",
                    value: "有一条「%@」分类的资料未保存，上次编辑于%@。",
                    comment: "Dashboard 草稿恢复提示，含分类和相对编辑时间"
                ),
                category,
                timeAgo
            )
        }
        public static func draftAlertMessage(timeAgo: String) -> String {
            String(
                format: NSLocalizedString(
                    "dashboard.draft_alert_message_with_time",
                    value: "有一条资料未保存，上次编辑于%@。",
                    comment: "Dashboard 草稿恢复提示，含相对编辑时间"
                ),
                timeAgo
            )
        }

        // Hero 卡片
        public static let welcome = NSLocalizedString("dashboard.welcome", value: "欢迎使用", comment: "欢迎使用")
        public static let welcomeSubtitle = NSLocalizedString("dashboard.welcome_subtitle", value: "添加第一条资料，开始整理", comment: "欢迎副标题")
        public static let captureItem = NSLocalizedString("dashboard.capture_item", value: "采集资料", comment: "采集资料按钮")
        // 问候语
        public static let defaultName = NSLocalizedString("dashboard.default_name", value: "用户", comment: "默认用户名")
        public static let greetingNight = NSLocalizedString("dashboard.greeting_night", value: "夜深了，注意休息", comment: "夜间问候")
        public static let greetingMorning = NSLocalizedString("dashboard.greeting_morning_generic", value: "早安", comment: "无昵称早间问候")
        public static let greetingAfternoon = NSLocalizedString("dashboard.greeting_afternoon_generic", value: "午安", comment: "无昵称午间问候")
        public static let greetingEvening = NSLocalizedString("dashboard.greeting_evening_generic", value: "晚上好", comment: "无昵称晚间问候")

        public static func greetingMorning(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_morning", value: "早安，%@", comment: "早间问候"), name)
        }

        public static func greetingAfternoon(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_afternoon", value: "午安，%@", comment: "午间问候"), name)
        }

        public static func greetingEvening(_ name: String) -> String {
            String(format: NSLocalizedString("dashboard.greeting_evening", value: "晚上好，%@", comment: "晚间问候"), name)
        }
    }

}
