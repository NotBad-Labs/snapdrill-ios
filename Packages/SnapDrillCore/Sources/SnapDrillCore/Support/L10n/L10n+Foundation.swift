//
//  L10n+Foundation.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 基础通用命名空间分片：Tab / AppRoot / Common / Activity / Notification。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Tab

    public enum Tab {
        public static let dashboard = NSLocalizedString("tab.dashboard", value: "首页", comment: "Tab 栏：首页")
        public static let library = NSLocalizedString("tab.library", value: "题库", comment: "Tab 栏：题库")
        public static let capture = NSLocalizedString("tab.capture", value: "采集", comment: "Tab 栏：采集")
        public static let review = NSLocalizedString("tab.review", value: "复习", comment: "Tab 栏：复习")
        public static let settings = NSLocalizedString("tab.settings", value: "设置", comment: "Tab 栏：设置")
    }

    // MARK: - AppRoot

    public enum AppRoot {
        public static let degradedModeTitle = NSLocalizedString("app_root.degraded_mode_title", value: "数据保护模式", comment: "降级模式标题")
        public static let degradedModeDescription = NSLocalizedString("app_root.degraded_mode_description", value: "数据仅保存在内存中，重启后将丢失。建议重启应用以恢复正常。", comment: "降级模式描述")
        public static let maintenanceTitle = NSLocalizedString("app_root.maintenance_title", value: "测试版维护中", comment: "维护页标题")
        public static let maintenanceDescription = NSLocalizedString("app_root.maintenance_description", value: "当前测试版本正在进行紧急维护或已失效，请稍后再试或前往 TestFlight 下载最新版本。", comment: "维护页描述")
        public static let checkUpdate = NSLocalizedString("app_root.check_update", value: "检查更新", comment: "检查更新按钮")
        public static let storeRecoveryNavigationTitle = NSLocalizedString("app_root.store_recovery.navigation_title", value: "数据恢复", comment: "损坏库恢复页导航标题")
        public static let storeRecoveryTitle = NSLocalizedString("app_root.store_recovery.title", value: "需要确认数据恢复方式", comment: "损坏库恢复页标题")
        public static let storeRecoveryDescription = NSLocalizedString(
            "app_root.store_recovery.description",
            value: "SnapDrill 无法打开当前资料空间的数据文件。为避免静默清空，应用已先打开一个空题库。",
            comment: "损坏库恢复页说明"
        )
        public static let storeRecoveryBackupCopyTitle = NSLocalizedString(
            "app_root.store_recovery.backup_copy_title",
            value: "原始文件已在本设备保留副本",
            comment: "损坏库隔离保留说明标题"
        )
        public static let storeRecoveryBackupCopyDescription = NSLocalizedString(
            "app_root.store_recovery.backup_copy_description",
            value: "你可以从 ZIP 备份恢复，或先以空题库继续使用。隔离副本不会自动进入备份。",
            comment: "损坏库隔离保留说明正文"
        )
        public static let storeRecoveryRestoreBackup = NSLocalizedString("app_root.store_recovery.restore_backup", value: "从备份恢复", comment: "损坏库恢复按钮")
        public static let storeRecoveryContinueEmpty = NSLocalizedString("app_root.store_recovery.continue_empty", value: "以空题库继续", comment: "损坏库空库继续按钮")
    }

    // MARK: - Common

    public enum Common {
        public static let ok = NSLocalizedString("common.ok", value: "确定", comment: "确定按钮")
        public static let cancel = NSLocalizedString("common.cancel", value: "取消", comment: "取消按钮")
        public static let save = NSLocalizedString("common.save", value: "保存", comment: "保存按钮")
        public static let delete = NSLocalizedString("common.delete", value: "删除", comment: "删除按钮")
        public static let edit = NSLocalizedString("common.edit", value: "编辑", comment: "编辑按钮")
        public static let done = NSLocalizedString("common.done", value: "完成", comment: "完成按钮")
        public static let retry = NSLocalizedString("common.retry", value: "重试", comment: "重试按钮")
        public static let close = NSLocalizedString("common.close", value: "关闭", comment: "关闭按钮")
        public static let loading = NSLocalizedString("common.loading", value: "加载中", comment: "加载中")
        public static let error = NSLocalizedString("common.error", value: "错误", comment: "错误")
        public static let create = NSLocalizedString("common.create", value: "创建", comment: "创建按钮")
        public static let discard = NSLocalizedString("common.discard", value: "放弃", comment: "放弃按钮")
        public static let reset = NSLocalizedString("common.reset", value: "重置", comment: "重置按钮")
        public static let notSelected = NSLocalizedString("common.not_selected", value: "未选择", comment: "未选择占位")
        public static let processing = NSLocalizedString("common.processing", value: "正在处理...", comment: "正在处理中")
        public static let comingSoon = NSLocalizedString("common.coming_soon", value: "即将上线", comment: "即将上线占位")
        public static let openSettings = NSLocalizedString("common.open_settings", value: "打开设置", comment: "打开设置按钮")
        public static let restartApp = NSLocalizedString("common.restart_app", value: "重启应用", comment: "重启应用按钮")
        public static let unknownError = NSLocalizedString("common.unknown_error", value: "未知错误", comment: "未知错误")

        // 相对日期
        public static let today = NSLocalizedString("common.today", value: "今天", comment: "今天")
        public static let tomorrow = NSLocalizedString("common.tomorrow", value: "明天", comment: "明天")
        public static let yesterday = NSLocalizedString("common.yesterday", value: "昨天", comment: "昨天")
        public static func daysLater(_ days: Int) -> String {
            String(format: NSLocalizedString("common.days_later", value: "%d天后", comment: "N天后"), days)
        }
        public static func daysAgo(_ days: Int) -> String {
            String(format: NSLocalizedString("common.days_ago", value: "%d天前", comment: "N天前"), days)
        }

        public static func itemCount(_ count: Int) -> String {
            String(format: NSLocalizedString("common.item_count", value: "%d 道题", comment: "题目数量"), count)
        }

        public static func itemCountShort(_ count: Int) -> String {
            String(format: NSLocalizedString("common.item_count_short", value: "%d 题", comment: "题目数量（短格式）"), count)
        }

    }

    // MARK: - Activity（Profile 切换阻塞提示）

    public enum Activity {
        public static let capturing = NSLocalizedString("activity.capturing", value: "正在采集", comment: "采集中阻塞切换提示")
        public static let exporting = NSLocalizedString("activity.exporting", value: "正在导出", comment: "导出中阻塞切换提示")
        public static let printing = NSLocalizedString("activity.printing", value: "正在打印", comment: "打印中阻塞切换提示")
        public static let backupRestore = NSLocalizedString("activity.backup_restore", value: "正在备份/恢复", comment: "备份恢复中阻塞切换提示")
    }

    // MARK: - Notification

    public enum Notification {
        public static let dailyTitle = NSLocalizedString("notification.daily.title", value: "复习时间到", comment: "每日复习通知标题")
        public static let dailyBody = NSLocalizedString("notification.daily.body", value: "今天的错题还在等你，快来复习吧！", comment: "每日复习通知正文")
    }
}
