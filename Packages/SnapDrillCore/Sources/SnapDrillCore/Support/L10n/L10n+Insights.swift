//
//  L10n+Insights.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 数据洞察分片：Dashboard / SmartPaper / Statistics。
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
        public static let subjectManage = NSLocalizedString("dashboard.subject_manage", value: "科目管理", comment: "科目管理卡片标题")
        public static let customize = NSLocalizedString("dashboard.customize", value: "自定义", comment: "自定义副标题")

        // 每日统计
        public static let todayAdded = NSLocalizedString("dashboard.today_added", value: "今日新增", comment: "今日新增")
        public static let todayReviewed = NSLocalizedString("dashboard.today_reviewed", value: "今日回顾", comment: "今日回顾")
        public static let dueReview = NSLocalizedString("dashboard.due_review", value: "待回顾", comment: "待回顾")
        public static let uncategorized = NSLocalizedString("dashboard.uncategorized", value: "未分类", comment: "统计中无分类维度值的资料分组")

        // 草稿恢复
        public static let draftAlertTitle = NSLocalizedString("dashboard.draft_alert_title", value: "恢复未完成的采集？", comment: "Dashboard 草稿恢复弹窗")
        public static let draftStartNew = NSLocalizedString("dashboard.draft_start_new", value: "开始新的", comment: "开始新的按钮")
        public static let draftRestore = NSLocalizedString("dashboard.draft_restore", value: "恢复", comment: "恢复按钮")
        public static let draftAlertMessage = NSLocalizedString("dashboard.draft_alert_message", value: "你有上次未保存的采集内容，是否继续编辑？", comment: "Dashboard 草稿恢复提示")
        public static func draftAlertMessage(subject: String, timeAgo: String) -> String {
            String(
                format: NSLocalizedString(
                    "dashboard.draft_alert_message_with_subject",
                    value: "有一条「%@」分类的资料未保存，上次编辑于%@。",
                    comment: "Dashboard 草稿恢复提示，含分类和相对编辑时间"
                ),
                subject,
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
        public static let todayDue = NSLocalizedString("dashboard.today_due", value: "今日待回顾", comment: "今日待回顾")
        public static let startNow = NSLocalizedString("dashboard.start_now", value: "立即开始", comment: "立即开始按钮")
        public static let allDone = NSLocalizedString("dashboard.all_done", value: "今日已完成", comment: "全部完成")
        public static let allDoneSubtitle = NSLocalizedString("dashboard.all_done_subtitle", value: "待回顾内容已处理完", comment: "全部完成副标题")

        // 问候语
        public static let defaultName = NSLocalizedString("dashboard.default_name", value: "用户", comment: "默认用户名")
        public static let greetingNight = NSLocalizedString("dashboard.greeting_night", value: "夜深了，注意休息", comment: "夜间问候")

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

    // MARK: - SmartPaper

    public enum SmartPaper {
        public static let title = NSLocalizedString("smart_paper.title", value: "智能组卷", comment: "智能组卷页标题")
        public static let subtitle = NSLocalizedString("smart_paper.subtitle", value: "自动选出最需要复习的题目，生成练习卷", comment: "智能组卷副标题")
        public static let generate = NSLocalizedString("smart_paper.generate", value: "生成试卷", comment: "生成试卷按钮")
        public static let questionCount = NSLocalizedString("smart_paper.question_count", value: "题目数量", comment: "选题数量配置项")
        public static let subjectFilter = NSLocalizedString("smart_paper.subject_filter", value: "分类", comment: "分类筛选配置项")
        public static let difficultyFilter = NSLocalizedString("smart_paper.difficulty_filter", value: "难度", comment: "难度筛选配置项")
        public static let allSubjects = NSLocalizedString("smart_paper.all_subjects", value: "全部分类", comment: "分类筛选：不限")
        public static let allDifficulties = NSLocalizedString("smart_paper.all_difficulties", value: "全部难度", comment: "难度筛选：不限")
        public static let noItemsTitle = NSLocalizedString("smart_paper.no_items_title", value: "暂无可选题目", comment: "无题目时的空状态标题")
        public static let noItemsMessage = NSLocalizedString("smart_paper.no_items_message", value: "当前筛选条件下没有题目，请调整筛选或先采集一些题目", comment: "无题目时的空状态描述")
        public static let pdfTitle = NSLocalizedString("smart_paper.pdf_title", value: "智能复习卷", comment: "智能组卷 PDF 封面标题")
        public static let proRequired = NSLocalizedString("smart_paper.pro_required", value: "智能组卷为 Pro 功能，敬请期待", comment: "Pro 功能即将上线占位（StoreKit 未接）")
        public static func selectedCount(_ count: Int) -> String {
            String(format: NSLocalizedString("smart_paper.selected_count", value: "已选 %d 题", comment: "已选题目数量"), count)
        }
    }

    // MARK: - Statistics

    public enum Statistics {
        public static let title = NSLocalizedString("statistics.title", value: "资料洞察", comment: "统计页标题")
        public static let subjectTrend = NSLocalizedString("statistics.subject_trend", value: "分类趋势", comment: "分类趋势图标题")
        public static let last30Days = NSLocalizedString("statistics.last_30_days", value: "最近 30 天", comment: "时间范围标签")
        public static let difficultyDistribution = NSLocalizedString("statistics.difficulty_distribution", value: "难度分布", comment: "难度分布图标题")
        public static let weakSubjects = NSLocalizedString("statistics.weak_subjects", value: "待回顾较多的分类", comment: "待回顾较多分类标题")
        public static let weakSubjectsHint = NSLocalizedString("statistics.weak_subjects_hint", value: "这些分类的待回顾内容较多", comment: "待回顾较多分类副标题")
        public static let noData = NSLocalizedString("statistics.no_data", value: "暂无数据", comment: "统计空状态标题")
        public static let noDataHint = NSLocalizedString("statistics.no_data_hint", value: "采集一些资料后即可查看数据洞察", comment: "统计空状态描述")
        public static let proRequired = NSLocalizedString("statistics.pro_required", value: "更多数据洞察稍后推出", comment: "Pro 功能即将上线占位（StoreKit 未接）")
        public static let questionsCount = NSLocalizedString("statistics.questions_count", value: "条", comment: "资料数量单位")
        public static func dueCount(_ count: Int) -> String {
            String(format: NSLocalizedString("statistics.due_count", value: "待回顾 %d 条", comment: "分类待回顾数"), count)
        }
    }
}
