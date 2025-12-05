//
//  LocalizationKeys.swift
//  NotBad
//
//  本地化字符串键定义
//

import Foundation

// MARK: - LocalizationKeys

/// 本地化字符串键
///
/// 集中管理所有本地化字符串，便于维护和国际化扩展。
enum L10n {

    // MARK: - Common

    enum Common {
        static let appName = String(localized: "app_name", defaultValue: "错题本")
        static let ok = String(localized: "common_ok", defaultValue: "确定")
        static let cancel = String(localized: "common_cancel", defaultValue: "取消")
        static let save = String(localized: "common_save", defaultValue: "保存")
        static let delete = String(localized: "common_delete", defaultValue: "删除")
        static let edit = String(localized: "common_edit", defaultValue: "编辑")
        static let done = String(localized: "common_done", defaultValue: "完成")
        static let back = String(localized: "common_back", defaultValue: "返回")
        static let next = String(localized: "common_next", defaultValue: "下一步")
        static let retry = String(localized: "common_retry", defaultValue: "重试")
        static let loading = String(localized: "common_loading", defaultValue: "加载中...")
        static let error = String(localized: "common_error", defaultValue: "错误")
        static let success = String(localized: "common_success", defaultValue: "成功")
    }

    // MARK: - Tabs

    enum Tab {
        static let dashboard = String(localized: "tab_dashboard", defaultValue: "首页")
        static let library = String(localized: "tab_library", defaultValue: "题库")
        static let capture = String(localized: "tab_capture", defaultValue: "录入")
        static let review = String(localized: "tab_review", defaultValue: "复习")
        static let profile = String(localized: "tab_profile", defaultValue: "我的")
    }

    // MARK: - Dashboard

    enum Dashboard {
        static let title = String(localized: "dashboard_title", defaultValue: "首页")
        static let totalItems = String(localized: "dashboard_total_items", defaultValue: "总错题数")
        static let pendingReview = String(localized: "dashboard_pending_review", defaultValue: "待复习")
        static let masteryRate = String(localized: "dashboard_mastery_rate", defaultValue: "掌握率")
        static let todayReview = String(localized: "dashboard_today_review", defaultValue: "今日复习")
        static let quickStart = String(localized: "dashboard_quick_start", defaultValue: "快速开始")
        static let recentItems = String(localized: "dashboard_recent_items", defaultValue: "最近添加")
    }

    // MARK: - Library

    enum Library {
        static let title = String(localized: "library_title", defaultValue: "题库")
        static let searchPlaceholder = String(localized: "library_search_placeholder", defaultValue: "搜索标题或知识点")
        static let filterAll = String(localized: "library_filter_all", defaultValue: "全部")
        static let emptyTitle = String(localized: "library_empty_title", defaultValue: "暂无错题")
        static let emptyDescription = String(localized: "library_empty_description", defaultValue: "快去录入你的第一道错题吧")
        static let advancedSearch = String(localized: "library_advanced_search", defaultValue: "高级搜索")
        static let sort = String(localized: "library_sort", defaultValue: "排序")
    }

    // MARK: - Capture

    enum Capture {
        static let title = String(localized: "capture_title", defaultValue: "录入错题")
        static let takePhoto = String(localized: "capture_take_photo", defaultValue: "拍照")
        static let selectFromAlbum = String(localized: "capture_select_album", defaultValue: "从相册选择")
        static let scanText = String(localized: "capture_scan_text", defaultValue: "扫描文本")
        static let recognizing = String(localized: "capture_recognizing", defaultValue: "识别中...")
        static let saveSuccess = String(localized: "capture_save_success", defaultValue: "保存成功")
    }

    // MARK: - Review

    enum Review {
        static let title = String(localized: "review_title", defaultValue: "复习")
        static let startReview = String(localized: "review_start", defaultValue: "开始复习")
        static let continueReview = String(localized: "review_continue", defaultValue: "继续复习")
        static let noItemsToReview = String(localized: "review_no_items", defaultValue: "暂无待复习错题")
        static let completed = String(localized: "review_completed", defaultValue: "复习完成")
        static let masteredWell = String(localized: "review_mastered_well", defaultValue: "掌握得很好")
        static let needsMorePractice = String(localized: "review_needs_practice", defaultValue: "需要多练习")
        
        /// 格式化复习次数
        ///
        /// - Parameter count: 复习次数
        /// - Returns: 本地化的复习次数描述，如「已复习 3 次」
        static func reviewedTimes(_ count: Int) -> String {
            String(format: String(localized: "review_times_format", defaultValue: "已复习 %d 次"), count)
        }
    }
    
    // MARK: - Review Status
    
    enum ReviewStatus {
        static let new = String(localized: "review_status_new", defaultValue: "新录入，尚未复习")
        static let today = String(localized: "review_status_today", defaultValue: "今天需要复习")
        
        /// 格式化逾期天数
        ///
        /// - Parameter days: 逾期天数
        /// - Returns: 本地化的逾期描述，如「已逾期 3 天」
        static func overdue(days: Int) -> String {
            String(format: String(localized: "review_status_overdue_format", defaultValue: "已逾期 %d 天"), days)
        }
        
        /// 格式化剩余天数
        ///
        /// - Parameter days: 距离下次复习的天数
        /// - Returns: 本地化的剩余天数描述，如「3 天后复习」
        static func inDays(_ days: Int) -> String {
            String(format: String(localized: "review_status_in_days_format", defaultValue: "%d 天后复习"), days)
        }
    }

    // MARK: - Profile

    enum Profile {
        static let title = String(localized: "profile_title", defaultValue: "我的")
        static let settings = String(localized: "profile_settings", defaultValue: "设置")
        static let dataManagement = String(localized: "profile_data_management", defaultValue: "数据管理")
        static let notifications = String(localized: "profile_notifications", defaultValue: "通知设置")
        static let appearance = String(localized: "profile_appearance", defaultValue: "外观设置")
        static let helpCenter = String(localized: "profile_help_center", defaultValue: "帮助中心")
        static let feedback = String(localized: "profile_feedback", defaultValue: "意见反馈")
        static let about = String(localized: "profile_about", defaultValue: "关于")
    }

    // MARK: - Subjects

    enum Subject {
        static let math = String(localized: "subject_math", defaultValue: "数学")
        static let chinese = String(localized: "subject_chinese", defaultValue: "语文")
        static let english = String(localized: "subject_english", defaultValue: "英语")
        static let physics = String(localized: "subject_physics", defaultValue: "物理")
        static let chemistry = String(localized: "subject_chemistry", defaultValue: "化学")
        static let biology = String(localized: "subject_biology", defaultValue: "生物")
        static let history = String(localized: "subject_history", defaultValue: "历史")
        static let geography = String(localized: "subject_geography", defaultValue: "地理")
        static let politics = String(localized: "subject_politics", defaultValue: "政治")
        static let other = String(localized: "subject_other", defaultValue: "其他")
    }

    // MARK: - Mastery Levels

    enum Mastery {
        static let none = String(localized: "mastery_none", defaultValue: "未掌握")
        static let poor = String(localized: "mastery_poor", defaultValue: "较差")
        static let partial = String(localized: "mastery_partial", defaultValue: "部分掌握")
        static let good = String(localized: "mastery_good", defaultValue: "掌握")
        static let excellent = String(localized: "mastery_excellent", defaultValue: "熟练")
    }

    // MARK: - Difficulty

    enum Difficulty {
        static let easy = String(localized: "difficulty_easy", defaultValue: "简单")
        static let medium = String(localized: "difficulty_medium", defaultValue: "中等")
        static let hard = String(localized: "difficulty_hard", defaultValue: "困难")
        static let expert = String(localized: "difficulty_expert", defaultValue: "极难")
    }

    // MARK: - Validation

    enum Validation {
        static let titleRequired = String(localized: "validation_title_required", defaultValue: "标题不能为空")
        static let contentSuggested = String(localized: "validation_content_suggested", defaultValue: "建议添加图片或笔记")
        static let knowledgePointsSuggested = String(localized: "validation_knowledge_points_suggested", defaultValue: "建议添加知识点标签")
        static let imageRequired = String(localized: "validation_image_required", defaultValue: "请添加错题图片")
    }

    // MARK: - Accessibility

    enum Accessibility {
        static let closeButton = String(localized: "a11y_close_button", defaultValue: "关闭")
        static let moreOptions = String(localized: "a11y_more_options", defaultValue: "更多选项")
        static let selectItem = String(localized: "a11y_select_item", defaultValue: "选择项目")
        static let deleteItem = String(localized: "a11y_delete_item", defaultValue: "删除项目")
        static let editItem = String(localized: "a11y_edit_item", defaultValue: "编辑项目")
    }
}

// MARK: - Formatted Strings

extension L10n {

    /// 格式化数量
    static func itemCount(_ count: Int) -> String {
        "\(count) 道"
    }

    /// 格式化百分比
    static func percentage(_ value: Double) -> String {
        let formatted = Int(value * 100)
        return "\(formatted)%"
    }

    /// 格式化复习进度
    static func reviewProgress(current: Int, total: Int) -> String {
        "\(current)/\(total)"
    }

    /// 格式化天数
    static func daysUntil(_ days: Int) -> String {
        if days == 0 {
            return "今天"
        } else if days == 1 {
            return "明天"
        } else if days < 0 {
            return "已逾期 \(-days) 天"
        } else {
            return "\(days) 天后"
        }
    }
}
