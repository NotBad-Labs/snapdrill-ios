//
//  L10n+Onboarding.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 引导页与个人资料分片：Onboarding / EditProfile。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Onboarding

    public enum Onboarding {
        public static let skip = NSLocalizedString("onboarding.skip", value: "跳过", comment: "引导页跳过按钮")
        public static let previous = NSLocalizedString("onboarding.previous", value: "上一页", comment: "引导页上一页按钮")
        public static let next = NSLocalizedString("onboarding.next", value: "下一页", comment: "引导页下一页按钮")
        public static let getStarted = NSLocalizedString("onboarding.get_started", value: "开始使用", comment: "引导页开始使用按钮")
        public static let accessibilityGroup = NSLocalizedString("onboarding.accessibility_group", value: "SnapDrill 入门引导", comment: "引导页无障碍分组标签")
        public static let pageWelcomeTitle = NSLocalizedString("onboarding.page_welcome_title", value: "欢迎使用 SnapDrill", comment: "引导页欢迎标题")
        public static let pageWelcomeDescription = NSLocalizedString("onboarding.page_welcome_description", value: "扫描、归档并整理题目与文档，稍后随时查找与回顾。", comment: "引导页欢迎描述")
        public static let pageCaptureTitle = NSLocalizedString("onboarding.page_capture_title", value: "快速采集", comment: "引导页采集标题")
        public static let pageCaptureDescription = NSLocalizedString("onboarding.page_capture_description", value: "拍照、导入图片或录入文字，把内容保存为可检索资料。", comment: "引导页采集描述")
        public static let pageReviewTitle = NSLocalizedString("onboarding.page_review_title", value: "按需回顾", comment: "引导页回顾标题")
        public static let pageReviewDescription = NSLocalizedString("onboarding.page_review_description", value: "把重要资料安排进回顾队列，减少遗漏。", comment: "引导页回顾描述")
        public static let pageExportTitle = NSLocalizedString("onboarding.page_export_title", value: "导出与打印", comment: "引导页导出标题")
        public static let pageExportDescription = NSLocalizedString("onboarding.page_export_description", value: "将资料导出为 PDF 或 CSV，便于打印、分享或备份。", comment: "引导页导出描述")
        public static let fieldConfigTitle = NSLocalizedString("onboarding.field_config_title", value: "选择资料字段", comment: "字段配置标题")
        public static let fieldConfigDescription = NSLocalizedString("onboarding.field_config_description", value: "选择录入资料时显示的字段，之后可在设置中调整。", comment: "字段配置描述")
        public static let fieldCategory = NSLocalizedString("onboarding.field_category", value: "分类", comment: "引导页字段：分类")
        public static let fieldSource = NSLocalizedString("onboarding.field_source", value: "来源", comment: "引导页字段：来源")
        public static let fieldDifficulty = NSLocalizedString("onboarding.field_difficulty", value: "难度", comment: "引导页字段：难度")
        public static let fieldLevel = NSLocalizedString("onboarding.field_level", value: "级别", comment: "引导页字段：级别")
        public static let fieldAnswer = NSLocalizedString("onboarding.field_answer", value: "答案", comment: "引导页字段：答案")
        public static let dismissTooltip = NSLocalizedString("onboarding.dismiss_tooltip", value: "关闭提示", comment: "关闭功能提示气泡按钮")
        public static let fieldConfigIcon = NSLocalizedString("onboarding.field_config_icon", value: "字段配置", comment: "字段配置图标无障碍标签")
        public static let fieldConfigHeader = NSLocalizedString("onboarding.field_config_header", value: "选择资料字段", comment: "字段配置标题无障碍标签")
    }

    // MARK: - EditProfile

    public enum EditProfile {
        public static let title = NSLocalizedString("edit_profile.title", value: "个人资料", comment: "个人资料页标题")
        public static let setAvatar = NSLocalizedString("edit_profile.set_avatar", value: "设置头像", comment: "设置头像按钮")
        public static let nickname = NSLocalizedString("edit_profile.nickname", value: "昵称", comment: "昵称标签")
        public static let nicknamePlaceholder = NSLocalizedString("edit_profile.nickname_placeholder", value: "请输入昵称", comment: "昵称占位符")
        public static let dailyGoal = NSLocalizedString("edit_profile.daily_goal", value: "每日回顾目标", comment: "每日回顾目标标签")
        public static let cardsCount = NSLocalizedString("edit_profile.cards_count", value: "条资料", comment: "资料数量单位")
        public static let motto = NSLocalizedString("edit_profile.motto", value: "个人备注", comment: "个人备注标签")
        public static let mottoPlaceholder = NSLocalizedString("edit_profile.motto_placeholder", value: "写一条个人备注...", comment: "个人备注占位符")
        public static let mottoFooter = NSLocalizedString("edit_profile.motto_footer", value: "这条备注会显示在首页和个人资料中", comment: "个人备注底部说明")
        public static let themeColor = NSLocalizedString("edit_profile.theme_color", value: "图标主题色", comment: "主题色标签")
        public static let fromPhotoLibrary = NSLocalizedString("edit_profile.from_photo_library", value: "从相册选择", comment: "从相册选择按钮")
        public static let systemIcon = NSLocalizedString("edit_profile.system_icon", value: "使用系统图标", comment: "系统图标按钮")
        public static let removeAvatar = NSLocalizedString("edit_profile.remove_avatar", value: "移除当前头像", comment: "移除头像按钮")
        public static let chooseAvatarSource = NSLocalizedString("edit_profile.choose_avatar_source", value: "选择头像来源", comment: "头像来源选择")
    }
}
