//
//  LocalizationKeys.swift
//  NotBadCore
//
//  Created by NotBad Architect on 2026/01/03.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  本地化键值定义
//

import Foundation

/// 本地化字符串键值
///
/// 使用枚举组织所有本地化字符串，提供类型安全的访问方式。
public enum L10n {
    // MARK: - Common
    public enum Common {
        public static let ok = NSLocalizedString("common.ok", comment: "确定按钮")
        public static let cancel = NSLocalizedString("common.cancel", comment: "取消按钮")
        public static let save = NSLocalizedString("common.save", comment: "保存按钮")
        public static let delete = NSLocalizedString("common.delete", comment: "删除按钮")
        public static let edit = NSLocalizedString("common.edit", comment: "编辑按钮")
        public static let done = NSLocalizedString("common.done", comment: "完成按钮")
        public static let retry = NSLocalizedString("common.retry", comment: "重试按钮")
        public static let close = NSLocalizedString("common.close", comment: "关闭按钮")
        public static let loading = NSLocalizedString("common.loading", comment: "加载中")
        public static let error = NSLocalizedString("common.error", comment: "错误")
        public static let openSettings = NSLocalizedString("common.open_settings", comment: "打开设置")
        public static let restartApp = NSLocalizedString("common.restart_app", comment: "重启应用")
        public static let unknownError = NSLocalizedString("common.unknown_error", comment: "未知错误")
    }
    
    // MARK: - Dashboard
    public enum Dashboard {
        public static let title = NSLocalizedString("dashboard.title", comment: "仪表板标题")
        public static let greeting = NSLocalizedString("dashboard.greeting", comment: "问候语")
        public static let todayReview = NSLocalizedString("dashboard.today_review", comment: "今日复习")
        public static let totalItems = NSLocalizedString("dashboard.total_items", comment: "总题目数")
        public static let startReview = NSLocalizedString("dashboard.start_review", comment: "开始复习")
    }
    
    // MARK: - Library
    public enum Library {
        public static let title = NSLocalizedString("library.title", comment: "题库标题")
        public static let allItems = NSLocalizedString("library.all_items", comment: "所有题目")
        public static let bySubject = NSLocalizedString("library.by_subject", comment: "按学科")
        public static let bySource = NSLocalizedString("library.by_source", comment: "按来源")
        public static let searchPlaceholder = NSLocalizedString("library.search_placeholder", comment: "搜索占位符")
        public static let noItems = NSLocalizedString("library.no_items", comment: "无题目提示")
    }
    
    // MARK: - Review
    public enum Review {
        public static let title = NSLocalizedString("review.title", comment: "复习标题")
        public static let question = NSLocalizedString("review.question", comment: "题目")
        public static let answer = NSLocalizedString("review.answer", comment: "答案")
        public static let showAnswer = NSLocalizedString("review.show_answer", comment: "显示答案")
        public static let hideAnswer = NSLocalizedString("review.hide_answer", comment: "隐藏答案")
        public static let difficulty = NSLocalizedString("review.difficulty", comment: "难度")
        public static let completed = NSLocalizedString("review.completed", comment: "已完成")
        public static let forgot = NSLocalizedString("review.forgot", comment: "忘记")
        public static let remember = NSLocalizedString("review.remember", comment: "记得")
        public static let hard = NSLocalizedString("review.hard", comment: "模糊/困难")
        public static let good = NSLocalizedString("review.good", comment: "熟悉/良好")
        public static let easy = NSLocalizedString("review.easy", comment: "简单")
    }
    
    // MARK: - Capture
    public enum Capture {
        public static let title = NSLocalizedString("capture.title", comment: "拍摄标题")
        public static let scanning = NSLocalizedString("capture.scanning", comment: "扫描中")
        public static let tapToCapture = NSLocalizedString("capture.tap_to_capture", comment: "点击拍摄")
        public static let processing = NSLocalizedString("capture.processing", comment: "处理中")
        public static let ocrFailed = NSLocalizedString("capture.ocr_failed", comment: "识别失败")
    }
    
    // MARK: - Settings
    public enum Settings {
        public static let title = NSLocalizedString("settings.title", comment: "设置标题")
        public static let general = NSLocalizedString("settings.general", comment: "通用")
        public static let privacy = NSLocalizedString("settings.privacy", comment: "隐私")
        public static let dataSync = NSLocalizedString("settings.data_sync", comment: "数据同步")
        public static let about = NSLocalizedString("settings.about", comment: "关于")
        public static let version = NSLocalizedString("settings.version", comment: "版本")
    }
    
    // MARK: - Edit Profile
    public enum EditProfile {
        public static let title = NSLocalizedString("edit_profile.title", comment: "个人资料")
        public static let setAvatar = NSLocalizedString("edit_profile.set_avatar", comment: "设置头像")
        public static let nickname = NSLocalizedString("edit_profile.nickname", comment: "昵称")
        public static let nicknamePlaceholder = NSLocalizedString("edit_profile.nickname_placeholder", comment: "请输入昵称")
        public static let dailyGoal = NSLocalizedString("edit_profile.daily_goal", comment: "每日目标")
        public static let cardsCount = NSLocalizedString("edit_profile.cards_count", comment: "张题目")
        public static let motto = NSLocalizedString("edit_profile.motto", comment: "学习座右铭")
        public static let mottoPlaceholder = NSLocalizedString("edit_profile.motto_placeholder", comment: "写一句话激励自己...")
        public static let mottoFooter = NSLocalizedString("edit_profile.motto_footer", comment: "座右铭底部说明")
        public static let themeColor = NSLocalizedString("edit_profile.theme_color", comment: "图标主题色")
        public static let fromPhotoLibrary = NSLocalizedString("edit_profile.from_photo_library", comment: "从相册选择")
        public static let systemIcon = NSLocalizedString("edit_profile.system_icon", comment: "使用系统图标")
        public static let removeAvatar = NSLocalizedString("edit_profile.remove_avatar", comment: "移除当前头像")
        public static let chooseAvatarSource = NSLocalizedString("edit_profile.choose_avatar_source", comment: "选择头像来源")
    }
    // MARK: - Errors
    public enum Errors {
        public static let networkUnavailable = NSLocalizedString("errors.network_unavailable", comment: "网络不可用")
        public static let icloudUnavailable = NSLocalizedString("errors.icloud_unavailable", comment: "iCloud不可用")
        public static let cameraPermissionDenied = NSLocalizedString("errors.camera_permission_denied", comment: "相机权限被拒绝")
        public static let photoPermissionDenied = NSLocalizedString("errors.photo_permission_denied", comment: "相册权限被拒绝")
        public static let exportFailed = NSLocalizedString("errors.export_failed", comment: "导出失败")
        public static let importFailed = NSLocalizedString("errors.import_failed", comment: "导入失败")
        public static let dataCorrupted = NSLocalizedString("errors.data_corrupted", comment: "数据损坏")
        public static let ocrFailed = NSLocalizedString("errors.ocr_failed", comment: "文字识别失败")
    }
    
    // MARK: - Subjects
    public enum Subjects {
        public static let math = NSLocalizedString("subjects.math", comment: "数学")
        public static let chinese = NSLocalizedString("subjects.chinese", comment: "语文")
        public static let english = NSLocalizedString("subjects.english", comment: "英语")
        public static let physics = NSLocalizedString("subjects.physics", comment: "物理")
        public static let chemistry = NSLocalizedString("subjects.chemistry", comment: "化学")
        public static let biology = NSLocalizedString("subjects.biology", comment: "生物")
        public static let history = NSLocalizedString("subjects.history", comment: "历史")
        public static let geography = NSLocalizedString("subjects.geography", comment: "地理")
        public static let politics = NSLocalizedString("subjects.politics", comment: "政治")
        public static let other = NSLocalizedString("subjects.other", comment: "其他")
    }
    
    // MARK: - Difficulty
    public enum Difficulty {
        public static let veryEasy = NSLocalizedString("difficulty.very_easy", comment: "非常简单")
        public static let easy = NSLocalizedString("difficulty.easy", comment: "简单")
        public static let medium = NSLocalizedString("difficulty.medium", comment: "中等")
        public static let hard = NSLocalizedString("difficulty.hard", comment: "困难")
        public static let veryHard = NSLocalizedString("difficulty.very_hard", comment: "非常困难")
        
        public static func text(for level: Int) -> String {
            switch level {
            case 1: return veryEasy
            case 2: return easy
            case 3: return medium
            case 4: return hard
            case 5: return veryHard
            default: return medium
            }
        }
    }
    
    // MARK: - Export
    public enum Export {
        public static let title = NSLocalizedString("export.title", comment: "导出标题")
        public static let pdf = NSLocalizedString("export.pdf", comment: "PDF格式")
        public static let csv = NSLocalizedString("export.csv", comment: "CSV格式")
        public static let json = NSLocalizedString("export.json", comment: "JSON格式")
        public static let exporting = NSLocalizedString("export.exporting", comment: "导出中")
        public static let success = NSLocalizedString("export.success", comment: "导出成功")
        public static let failed = NSLocalizedString("export.failed", comment: "导出失败")
    }
}

/// 本地化辅助工具
public enum LocalizationHelper {
    /// 获取当前语言代码
    public static var currentLanguageCode: String {
        return Locale.current.language.languageCode?.identifier ?? "zh"
    }
    
    /// 是否为中文环境
    public static var isChineseLocale: Bool {
        return currentLanguageCode.hasPrefix("zh")
    }
    
    /// 是否为英文环境
    public static var isEnglishLocale: Bool {
        return currentLanguageCode.hasPrefix("en")
    }
    
    /// 格式化数字（带本地化）
    public static func formatNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    /// 格式化日期（带本地化）
    public static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    /// 格式化时间（带本地化）
    public static func formatTime(_ date: Date, style: DateFormatter.Style = .short) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = style
        return formatter.string(from: date)
    }
    
    /// 格式化日期时间（带本地化）
    public static func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}


