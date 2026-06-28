//
//  L10n+Settings.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 设置分片：Settings。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Settings

    public enum Settings {
        public static let title = NSLocalizedString("settings.title", value: "设置", comment: "设置标题")

        // 录入字段
        public static let captureFields = NSLocalizedString("settings.capture_fields", value: "录入字段", comment: "录入字段区标题")
        public static let fieldCategory = NSLocalizedString("settings.field_category", value: "分类", comment: "分类字段")
        public static let fieldSource = NSLocalizedString("settings.field_source", value: "来源", comment: "来源字段")
        public static let fieldLevel = NSLocalizedString("settings.field_level", value: "级别", comment: "级别字段")
        public static let fieldAnswer = NSLocalizedString("settings.field_answer", value: "答案", comment: "答案字段")

        // 回顾设置
        public static let reviewSettings = NSLocalizedString("settings.review_settings", value: "回顾设置", comment: "回顾设置区标题")
        public static let cardAppearance = NSLocalizedString("settings.card_appearance", value: "卡片外观", comment: "卡片外观")
        public static let reviewReminder = NSLocalizedString("settings.review_reminder", value: "回顾提醒", comment: "回顾提醒")
        public static let privacyAndExport = NSLocalizedString("settings.privacy_export", value: "隐私与导出", comment: "隐私与导出")

        // 数据与备份（云同步未实现，阻塞 #485；文案对齐 cloudKitDatabase: .none #15）
        public static let dataAndSync = NSLocalizedString("settings.data_and_sync", value: "数据与备份", comment: "数据与备份（当前版本仅本地 + 手动备份；iCloud 同步阻塞 #485）")
        public static let storageManagement = NSLocalizedString("settings.storage_management", value: "存储管理", comment: "存储管理")
        public static let storageImages = NSLocalizedString("settings.storage_images", value: "资料图片", comment: "图片存储占用")
        public static let storageTotal = NSLocalizedString("settings.storage_total", value: "总占用", comment: "总存储占用")
        public static let storageFooter = NSLocalizedString("settings.storage_footer", value: "显示当前资料空间的存储占用。图片会自动压缩以节省空间。", comment: "存储管理说明")

        // 通用
        public static let general = NSLocalizedString("settings.general", value: "通用", comment: "通用区标题")
        public static let appearance = NSLocalizedString("settings.appearance", value: "外观", comment: "外观")
        public static let followSystem = NSLocalizedString("settings.follow_system", value: "跟随系统", comment: "跟随系统")
        public static let lightMode = NSLocalizedString("settings.light_mode", value: "浅色", comment: "浅色模式")
        public static let darkMode = NSLocalizedString("settings.dark_mode", value: "深色", comment: "深色模式")
        public static let language = NSLocalizedString("settings.language", value: "语言", comment: "语言")
        public static let simplifiedChinese = NSLocalizedString("settings.simplified_chinese", value: "简体中文", comment: "简体中文")

        // 数据管理
        public static let dataManagement = NSLocalizedString("settings.data_management", value: "数据管理", comment: "数据管理区标题")
        public static let manageCategories = NSLocalizedString("settings.manage_categories", value: "管理分类维度", comment: "管理分类维度（L3 动态维度统一入口）")
        public static let manageSources = NSLocalizedString("settings.manage_sources", value: "管理来源", comment: "管理来源")
        public static let manageLevels = NSLocalizedString("settings.manage_levels", value: "管理级别", comment: "管理级别")
        public static let clearAllData = NSLocalizedString("settings.clear_all_data", value: "清空所有数据", comment: "清空所有数据")
        public static let clearConfirmTitle = NSLocalizedString("settings.clear_confirm_title", value: "确认清空所有数据？", comment: "清空确认标题")
        public static let clearConfirmMessage = NSLocalizedString("settings.clear_confirm_message", value: "此操作将删除所有资料、分类和标签，且不可恢复。", comment: "清空确认信息")
        public static let clearConfirmButton = NSLocalizedString("settings.clear_confirm_button", value: "清空所有", comment: "确认清空按钮")
        public static let clearFailed = NSLocalizedString("settings.clear_failed", value: "清空数据失败，请稍后重试", comment: "清空数据失败错误")
        public static let dangerZone = NSLocalizedString("settings.danger_zone", value: "危险操作", comment: "危险操作分区标题")
        public static let dangerZoneFooter = NSLocalizedString("settings.danger_zone_footer", value: "以下操作不可撤销，请谨慎使用", comment: "危险操作分区说明")
        public static let categoryManagement = NSLocalizedString("settings.category_management", value: "分类管理", comment: "分类管理分区标题")

        // 关于
        public static let about = NSLocalizedString("settings.about", value: "关于", comment: "关于区标题")
        public static let version = NSLocalizedString("settings.version", value: "版本", comment: "版本")
        public static let privacyPolicy = NSLocalizedString("settings.privacy_policy", value: "隐私政策", comment: "隐私政策")
        public static let termsOfService = NSLocalizedString("settings.terms_of_service", value: "服务条款", comment: "服务条款")
        public static let licenses = NSLocalizedString("settings.licenses", value: "开源许可", comment: "开源许可")
        public static let helpCenter = NSLocalizedString("settings.help_center", value: "帮助中心", comment: "帮助中心")

        // 通知设置
        public static let notificationTitle = NSLocalizedString("settings.notification_title", value: "回顾提醒", comment: "通知设置标题")
        public static let dailyReminder = NSLocalizedString("settings.daily_reminder", value: "每日回顾提醒", comment: "每日回顾提醒")
        public static let reminderTime = NSLocalizedString("settings.reminder_time", value: "提醒时间", comment: "提醒时间")
        public static let reminderSound = NSLocalizedString("settings.reminder_sound", value: "提醒声音", comment: "提醒声音")
        public static let notificationDenied = NSLocalizedString("settings.notification_denied", value: "通知权限未开启", comment: "通知权限弹窗标题")
        public static let notificationDeniedMessage = NSLocalizedString("settings.notification_denied_message", value: "请在 iPhone 设置中开启 SnapDrill 的通知权限。", comment: "通知权限提示")
        public static let goToSettings = NSLocalizedString("settings.go_to_settings", value: "前往设置", comment: "前往设置按钮")

        // 语言设置
        public static let languageTitle = NSLocalizedString("settings.language_title", value: "语言设置", comment: "语言设置页标题")
        public static let languageHint = NSLocalizedString("settings.language_hint", value: "应用语言跟随系统设置。如需更改，请在 iPhone 的「设置 > 通用 > 语言与地区」中调整。", comment: "语言设置提示")
        public static let openSystemSettings = NSLocalizedString("settings.open_system_settings", value: "打开系统设置", comment: "打开系统设置")
        public static let currentLanguage = NSLocalizedString("settings.current_language", value: "当前语言", comment: "当前语言")

        public static let backup = NSLocalizedString("settings.backup", value: "备份与恢复", comment: "备份与恢复区标题")
        public static let createBackup = NSLocalizedString("settings.create_backup", value: "创建备份", comment: "创建备份")
        public static let restoreBackup = NSLocalizedString("settings.restore_backup", value: "恢复备份", comment: "恢复备份")
        public static let backupHint = NSLocalizedString("settings.backup_hint", value: "备份文件包含所有资料和分类数据", comment: "备份说明")
        public static let restoreConfirmTitle = NSLocalizedString("settings.restore_confirm_title", value: "确认恢复？", comment: "恢复确认标题")
        public static let restoreConfirmMessage = NSLocalizedString("settings.restore_confirm_message", value: "恢复将覆盖当前所有数据，恢复前会自动创建备份。", comment: "恢复确认信息")
        public static let restoreConfirmButton = NSLocalizedString("settings.restore_confirm_button", value: "恢复", comment: "确认恢复按钮")
        public static let localDataTitle = NSLocalizedString("settings.local_data_title", value: "本地保存", comment: "本地数据提示标题")
        public static let localDataWarning = NSLocalizedString("settings.local_data_warning", value: "资料仅存储在本设备。换机、卸载或清空设备前，请先创建备份。", comment: "本地数据警告")

        // 备份状态消息
        public static let backupPreparingData = NSLocalizedString("settings.backup_preparing_data", value: "正在准备数据...", comment: "备份状态：准备数据")
        public static let backupComplete = NSLocalizedString("settings.backup_complete", value: "备份完成", comment: "备份状态：完成")
        public static let restoreVerifying = NSLocalizedString("settings.restore_verifying", value: "正在验证备份文件...", comment: "恢复状态：验证中")
        public static let restoreAutoBackup = NSLocalizedString("settings.restore_auto_backup", value: "正在恢复前自动备份当前数据...", comment: "恢复状态：自动备份")
        public static let restoreReadingData = NSLocalizedString("settings.restore_reading_data", value: "正在读取备份数据...", comment: "恢复状态：读取数据")
        public static let restoreImages = NSLocalizedString("settings.restore_images", value: "正在恢复图片...", comment: "恢复状态：恢复图片")
        public static let restoreComplete = NSLocalizedString("settings.restore_complete", value: "恢复完成", comment: "恢复状态：完成")
        public static let restorePartialImageFailure = NSLocalizedString("settings.restore_partial_image_failure", value: "数据已恢复，但部分图片恢复失败。可尝试重新恢复以修复图片。", comment: "恢复状态：图片部分失败")

        public static func backupPackingItems(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.backup_packing_items", value: "正在打包 %d 条资料...", comment: "备份状态：打包资料"), count)
        }

        public static func restoreRestoringItems(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.restore_restoring_items", value: "正在恢复 %d 条资料...", comment: "恢复状态：恢复资料"), count)
        }

        // 开源许可
        public static let openSourceSection = NSLocalizedString("settings.open_source_section", value: "开源库", comment: "开源库区标题")
        public static let openSourceThanks = NSLocalizedString("settings.open_source_thanks", value: "本应用使用了以上优秀的开源软件，感谢所有贡献者。", comment: "开源库致谢")
        public static let openSourceTitle = NSLocalizedString("settings.open_source_title", value: "开源许可", comment: "开源许可页标题")
        public static let avatarColor = NSLocalizedString("settings.avatar_color", value: "头像颜色", comment: "头像颜色选择器无障碍标签")

        // 隐私设置
        public static let privacyTitle = NSLocalizedString("settings.privacy_title", value: "隐私与数据导出", comment: "隐私设置标题")
        public static let analyticsEnabled = NSLocalizedString("settings.analytics_enabled", value: "本地诊断偏好", comment: "本地诊断偏好")
        public static let analyticsHint = NSLocalizedString("settings.analytics_hint", value: "当前版本不发送使用分析或崩溃报告；此设置仅保存本地偏好。", comment: "本地诊断偏好说明")
        public static let crashReporting = NSLocalizedString("settings.crash_reporting", value: "崩溃报告", comment: "崩溃报告")
        public static let crashReportingHint = NSLocalizedString("settings.crash_reporting_hint", value: "当前版本不自动发送崩溃报告。诊断信息仅保留在设备本地，或来自 Apple 聚合报告。", comment: "崩溃报告说明")
        public static let telemetryEnabled = NSLocalizedString("settings.telemetry_enabled", value: "本地诊断偏好", comment: "本地诊断偏好")
        public static let dataExport = NSLocalizedString("settings.data_export", value: "数据导出", comment: "数据导出区标题")
        public static let exportJSON = NSLocalizedString("settings.export_json", value: "导出为 JSON", comment: "JSON 导出")
        public static let exportCSV = NSLocalizedString("settings.export_csv", value: "导出为 CSV", comment: "CSV 导出")
        public static let exportHint = NSLocalizedString("settings.export_hint", value: "导出所有资料数据，可用于数据迁移或备份。", comment: "导出说明")

        // 卡片外观
        public static let cardAppearanceTitle = NSLocalizedString("settings.card_appearance_title", value: "卡片外观", comment: "卡片外观设置标题")
        public static let cardFront = NSLocalizedString("settings.card_front", value: "正面（资料）", comment: "正面区标签")
        public static let cardBack = NSLocalizedString("settings.card_back", value: "背面（参考内容）", comment: "背面区标签")
        public static let textAlignment = NSLocalizedString("settings.text_alignment", value: "文字对齐", comment: "文字对齐")
        public static let alignLeft = NSLocalizedString("settings.align_left", value: "左对齐", comment: "左对齐")
        public static let alignCenter = NSLocalizedString("settings.align_center", value: "居中", comment: "居中")
        public static let alignRight = NSLocalizedString("settings.align_right", value: "右对齐", comment: "右对齐")
        public static let fontSize = NSLocalizedString("settings.font_size", value: "字体大小", comment: "字体大小")
        public static let previewText = NSLocalizedString("settings.preview_text", value: "预览效果文字", comment: "预览效果文字")

        // 个人资料
        public static let editProfile = NSLocalizedString("settings.edit_profile", value: "个人资料", comment: "个人资料")
        public static let nickname = NSLocalizedString("settings.nickname", value: "昵称", comment: "昵称")
        public static let nicknamePlaceholder = NSLocalizedString("settings.nickname_placeholder", value: "请输入昵称", comment: "昵称输入占位")
        public static let dailyGoal = NSLocalizedString("settings.daily_goal", value: "每日回顾目标", comment: "每日回顾目标")
        public static let cardsUnit = NSLocalizedString("settings.cards_unit", value: "条", comment: "条（资料单位）")
        public static let motto = NSLocalizedString("settings.motto", value: "个人备注", comment: "个人备注")
        public static let mottoPlaceholder = NSLocalizedString("settings.motto_placeholder", value: "写一条个人备注...", comment: "个人备注输入占位")
        public static let mottoFooter = NSLocalizedString("settings.motto_footer", value: "个人备注将显示在个人资料中", comment: "个人备注说明")
        public static let themeColor = NSLocalizedString("settings.theme_color", value: "图标主题色", comment: "图标主题色")
        public static let avatarSource = NSLocalizedString("settings.avatar_source", value: "选择头像来源", comment: "选择头像来源")
        public static let fromPhotoLibrary = NSLocalizedString("settings.from_photo_library", value: "从相册选择", comment: "从相册选择")
        public static let systemIcon = NSLocalizedString("settings.system_icon", value: "使用系统图标", comment: "使用系统图标")
        public static let removeAvatar = NSLocalizedString("settings.remove_avatar", value: "移除当前头像", comment: "移除当前头像")

        // Profile 管理
        public static let switchLearner = NSLocalizedString("settings.switch_learner", value: "切换资料空间", comment: "切换资料空间入口")
        public static let profileSpacesSection = NSLocalizedString("settings.profile_spaces_section", value: "资料空间", comment: "资料空间列表区标题")
        public static let profileSpacesFooter = NSLocalizedString("settings.profile_spaces_footer", value: "每个资料空间独立保存资料、图片和回顾进度，适合按项目或场景分开管理。", comment: "资料空间列表说明")
        public static let defaultProfileName = NSLocalizedString("settings.default_profile_name", value: "默认资料空间", comment: "默认资料空间名称")
        public static let addLearner = NSLocalizedString("settings.add_learner", value: "添加资料空间", comment: "添加资料空间按钮")
        public static let deleteLearnerConfirm = NSLocalizedString("settings.delete_learner_confirm", value: "删除后该资料空间的所有资料、回顾进度和图片将永久丢失，无法恢复。", comment: "删除资料空间确认")
        public static let learnerName = NSLocalizedString("settings.learner_name", value: "资料空间名称", comment: "资料空间名称输入")
        public static let currentLearner = NSLocalizedString("settings.current_learner", value: "当前", comment: "当前资料空间标记")
        public static let profileCurrentHint = NSLocalizedString("settings.profile_current_hint", value: "当前正在使用的资料空间", comment: "当前资料空间无障碍提示")
        public static let profileSwitchHint = NSLocalizedString("settings.profile_switch_hint", value: "切换到此资料空间", comment: "切换资料空间无障碍提示")
        public static let draftExistsTitle = NSLocalizedString("settings.draft_exists_title", value: "存在未保存的草稿", comment: "切换资料空间时草稿提示标题")
        public static let draftExistsMessage = NSLocalizedString("settings.draft_exists_message", value: "当前有未完成的录入草稿，切换资料空间后草稿将被丢弃。", comment: "切换资料空间时草稿提示详情")
        public static let discardDraft = NSLocalizedString("settings.discard_draft", value: "放弃草稿并切换", comment: "放弃草稿确认按钮")

        // 反馈
        public static let feedbackAndSupport = NSLocalizedString("settings.feedback_and_support", value: "反馈与支持", comment: "反馈与支持")
        public static let feedbackTitle = NSLocalizedString("settings.feedback_title", value: "意见反馈", comment: "意见反馈弹窗标题")
        public static let copyEmail = NSLocalizedString("settings.copy_email", value: "复制邮箱", comment: "复制邮箱按钮")
        public static let maybeLater = NSLocalizedString("settings.maybe_later", value: "以后再说", comment: "以后再说按钮")
        public static let feedbackMessage = NSLocalizedString("settings.feedback_message", value: "感谢您使用 SnapDrill！您可以发送邮件至 hello@notbadhq.com，或直接在 TestFlight 中反馈。", comment: "反馈提示信息")
        public static let editProfileSubtitle = NSLocalizedString("settings.edit_profile_subtitle", value: "编辑个人资料", comment: "编辑个人资料副标题")

        public static let backupData = NSLocalizedString("settings.backup_data", value: "创建备份", comment: "创建备份按钮")
        public static let backupDataSubtitle = NSLocalizedString("settings.backup_data_subtitle", value: "导出包含资料、分类设置和图片的 ZIP 文件", comment: "创建备份说明")
        public static let restoreData = NSLocalizedString("settings.restore_data", value: "恢复备份", comment: "恢复备份按钮")
        public static let restoreDataSubtitle = NSLocalizedString("settings.restore_data_subtitle", value: "从 ZIP 备份恢复，会替换当前资料空间", comment: "恢复备份说明")
        public static let backupFooter = NSLocalizedString("settings.backup_footer", value: "备份文件包含所有资料、分类设置和图片。恢复操作将替换当前全部数据。", comment: "备份说明")

        // 数据导入
        public static let importData = NSLocalizedString("settings.import_data", value: "数据导入", comment: "数据导入区标题")
        public static let importCSV = NSLocalizedString("settings.import_csv", value: "导入 CSV", comment: "导入 CSV")
        public static let importCSVSubtitle = NSLocalizedString("settings.import_csv_subtitle", value: "从表格文件批量导入资料", comment: "CSV 导入按钮说明")
        public static let importCSVHint = NSLocalizedString("settings.import_csv_hint", value: "从 CSV 文件导入资料数据（需包含 Content 或 Category 列）", comment: "CSV 导入说明")
        public static let importReading = NSLocalizedString("settings.import_reading", value: "正在读取文件…", comment: "导入状态：读取")
        public static let importParsing = NSLocalizedString("settings.import_parsing", value: "正在解析数据…", comment: "导入状态：解析")
        public static func importSaving(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.import_saving", value: "正在导入 %d 条资料…", comment: "导入状态：保存资料"), count)
        }
        public static func importComplete(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.import_complete", value: "成功导入 %d 条资料", comment: "导入完成资料"), count)
        }
        public static let importFailed = NSLocalizedString("settings.import_failed", value: "导入失败", comment: "导入失败")
        public static let importNoValidRows = NSLocalizedString("settings.import_no_valid_rows", value: "CSV 文件中没有有效数据行", comment: "无有效行")
        public static let importCSVFormat = NSLocalizedString("settings.import_csv_format", value: "CSV 首行需包含列名：Content, Category, Answer, Tags 等", comment: "CSV 格式说明")
        public static let restoreDialogTitle = NSLocalizedString("settings.restore_dialog_title", value: "恢复数据", comment: "恢复数据对话框标题")
        public static let selectBackupFile = NSLocalizedString("settings.select_backup_file", value: "选择备份文件", comment: "选择备份文件按钮")
        public static let restoreDialogMessage = NSLocalizedString("settings.restore_dialog_message", value: "恢复将替换当前所有数据，此操作不可撤销。恢复前会自动备份当前数据到临时目录。", comment: "恢复对话框提示")
        public static let operationFailed = NSLocalizedString("settings.operation_failed", value: "操作失败", comment: "操作失败弹窗标题")
        public static let unknownError = NSLocalizedString("settings.unknown_error", value: "未知错误", comment: "未知错误")
        public static let restoreSuccess = NSLocalizedString("settings.restore_success", value: "恢复成功", comment: "恢复成功弹窗标题")

        // 存储空间
        public static let storageSpace = NSLocalizedString("settings.storage_space", value: "存储空间", comment: "存储空间区标题")
        public static let mediaCacheUsage = NSLocalizedString("settings.media_cache_usage", value: "临时缓存", comment: "临时缓存占用")
        public static let mediaCacheSubtitle = NSLocalizedString("settings.media_cache_subtitle", value: "临时图片和下载资源，可安全清理", comment: "临时缓存说明")
        public static let calculating = NSLocalizedString("settings.calculating", value: "计算中...", comment: "计算中")
        public static let clearCache = NSLocalizedString("settings.clear_cache", value: "清理缓存", comment: "清理缓存按钮")
        public static let clearCacheTitle = NSLocalizedString("settings.clear_cache_title", value: "清理缓存", comment: "清理缓存弹窗标题")
        public static let clearCacheAction = NSLocalizedString("settings.clear_cache_action", value: "清理", comment: "清理按钮")
        public static let clearCacheMessage = NSLocalizedString("settings.clear_cache_message", value: "清理缓存不会删除您的资料数据，仅删除临时图片和下载的资源。", comment: "清理缓存提示")

        // 数据维护
        public static let dataMaintenance = NSLocalizedString("settings.data_maintenance", value: "数据维护", comment: "数据维护区标题")
        public static let autoArchiveOldItems = NSLocalizedString("settings.auto_archive_old_items", value: "自动归档旧资料", comment: "自动归档旧资料")
        public static let archiveTime = NSLocalizedString("settings.archive_time", value: "归档时间", comment: "归档时间")
        public static let daysAgo30 = NSLocalizedString("settings.days_ago_30", value: "30 天前", comment: "30 天前")
        public static let daysAgo60 = NSLocalizedString("settings.days_ago_60", value: "60 天前", comment: "60 天前")
        public static let daysAgo90 = NSLocalizedString("settings.days_ago_90", value: "90 天前", comment: "90 天前")
        public static let daysAgo180 = NSLocalizedString("settings.days_ago_180", value: "180 天前", comment: "180 天前")
        public static let dataMaintenanceFooter = NSLocalizedString("settings.data_maintenance_footer", value: "自动归档长期未回顾的资料，保持资料库轻量化。归档后的资料仍可搜索但不会自动安排回顾。", comment: "数据维护说明")

        // 通知设置详情
        public static let enableDailyReminder = NSLocalizedString("settings.enable_daily_reminder", value: "启用每日回顾提醒", comment: "启用每日回顾提醒")
        public static let dailyReminderSection = NSLocalizedString("settings.daily_reminder_section", value: "每日提醒", comment: "每日提醒区标题")
        public static let notificationStyle = NSLocalizedString("settings.notification_style", value: "通知样式", comment: "通知样式区标题")
        public static let sound = NSLocalizedString("settings.sound", value: "声音", comment: "声音")
        public static let notificationStyleFooter = NSLocalizedString("settings.notification_style_footer", value: "声音设置在下次触发通知时生效", comment: "通知样式说明")
        public static let notificationAndReminder = NSLocalizedString("settings.notification_and_reminder", value: "通知与提醒", comment: "通知与提醒页标题")
        public static let permissionDeniedTitle = NSLocalizedString("settings.permission_denied_title", value: "通知权限被拒绝", comment: "通知权限被拒绝弹窗标题")
        public static let permissionDeniedMessage = NSLocalizedString("settings.permission_denied_message", value: "请在「设置 → 通知 → SnapDrill」中开启通知权限，才能接收每日回顾提醒。", comment: "通知权限被拒绝说明")
        public static let rescheduleFailedTitle = NSLocalizedString("settings.reschedule_failed_title", value: "更新提醒时间失败", comment: "更新提醒时间失败")
        public static let rescheduleFailedMessage = NSLocalizedString("settings.reschedule_failed_message", value: "无法设置提醒时间，请稍后重试", comment: "更新提醒时间失败说明")

        public static func reminderEnabledFooter(_ hour: Int, _ minute: String) -> String {
            String(format: NSLocalizedString("settings.reminder_enabled_footer", value: "将在每天 %d:%@ 提醒你回顾今日资料", comment: "提醒已开启说明"), hour, minute)
        }

        public static let reminderDisabledFooter = NSLocalizedString("settings.reminder_disabled_footer", value: "开启后系统将在固定时间推送回顾提醒", comment: "提醒未开启说明")

        // 隐私设置详情
        public static let dataCollection = NSLocalizedString("settings.data_collection", value: "诊断与数据", comment: "数据收集区标题")
        public static let useAnalytics = NSLocalizedString("settings.use_analytics", value: "本地诊断偏好", comment: "本地诊断偏好")
        public static let diagnosticsLocalOnly = NSLocalizedString("settings.diagnostics_local_only", value: "仅本地诊断", comment: "本地诊断说明标题")
        public static let dataCollectionFooter = NSLocalizedString("settings.data_collection_footer", value: "当前版本不发送使用分析、崩溃报告或资料内容。诊断信息仅保留在设备本地，或来自 Apple 聚合报告。", comment: "数据收集说明")
        public static let exportMyData = NSLocalizedString("settings.export_my_data", value: "导出我的数据", comment: "导出我的数据")
        public static let exporting = NSLocalizedString("settings.exporting", value: "导出中...", comment: "导出中")
        public static let chooseExportFormat = NSLocalizedString("settings.choose_export_format", value: "选择导出格式", comment: "选择导出格式")
        public static let jsonFormat = NSLocalizedString("settings.json_format", value: "JSON 格式", comment: "JSON 格式")
        public static let csvFormat = NSLocalizedString("settings.csv_format", value: "CSV 格式", comment: "CSV 格式")
        public static let exportDataFooter = NSLocalizedString("settings.export_data_footer", value: "导出所有本地资料数据为 JSON 或 CSV 格式", comment: "导出数据说明")
        public static let privacyAndSecurity = NSLocalizedString("settings.privacy_and_security", value: "隐私与安全", comment: "隐私与安全页标题")

        public static func exportFailed(_ message: String) -> String {
            String(format: NSLocalizedString("settings.export_failed", value: "导出失败: %@", comment: "导出失败"), message)
        }

        // 语言设置详情
        public static let languageRestartHint = NSLocalizedString("settings.language_restart_hint", value: "切换语言后需重启应用生效", comment: "语言切换重启提示")
        public static let languageChangeTitle = NSLocalizedString("settings.language_change_title", value: "语言已切换", comment: "语言切换成功弹窗标题")
        public static let languageChangeMessage = NSLocalizedString("settings.language_change_message", value: "请重新启动应用以应用新语言", comment: "语言切换重启说明")

        // 卡片外观详情
        public static let cardFrontSection = NSLocalizedString("settings.card_front_section", value: "卡片正面 (资料)", comment: "卡片正面区标题")
        public static let cardBackSection = NSLocalizedString("settings.card_back_section", value: "卡片背面 (参考内容)", comment: "卡片背面区标题")
        public static let cardFrontPreview = NSLocalizedString("settings.card_front_preview", value: "已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。", comment: "卡片正面预览文本")
        public static let cardBackPreview = NSLocalizedString("settings.card_back_preview", value: "内容：已知 △ABC 中，AB = AC，∠A = 36°，求 ∠B 的度数。", comment: "卡片背面预览文本")
        public static let alignment = NSLocalizedString("settings.alignment", value: "对齐方式", comment: "对齐方式")

        public static func fontSizeLabel(_ size: Int) -> String {
            String(format: NSLocalizedString("settings.font_size_label", value: "字体大小: %d", comment: "字体大小标签"), size)
        }

        // DEBUG
        public static let debugTitle = NSLocalizedString("settings.debug_title", value: "开发调试", comment: "开发调试区标题")
        public static let generateMockData = NSLocalizedString("settings.generate_mock_data", value: "生成模拟数据", comment: "生成模拟数据")
        public static let clearMockData = NSLocalizedString("settings.clear_mock_data", value: "清空模拟数据", comment: "清空模拟数据")
        public static let generating = NSLocalizedString("settings.generating", value: "生成中...", comment: "生成中")

        public static func generateTestData(_ count: Int) -> String {
            String(format: NSLocalizedString("settings.generate_test_data", value: "生成测试数据 (%d条)", comment: "生成测试数据按钮"), count)
        }
    }
}
