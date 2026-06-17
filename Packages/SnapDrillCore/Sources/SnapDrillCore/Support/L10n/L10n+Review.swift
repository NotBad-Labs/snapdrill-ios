//
//  L10n+Review.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 回顾分片：Review。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Review

    public enum Review {
        public static let title = NSLocalizedString("review.title", value: "回顾", comment: "回顾标题")

        // 暂停弹窗
        public static let pauseAlertTitle = NSLocalizedString("review.pause_alert_title", value: "确认暂停回顾？", comment: "暂停回顾弹窗")
        public static let pauseContinue = NSLocalizedString("review.pause_continue", value: "继续", comment: "继续按钮")
        public static let pauseConfirm = NSLocalizedString("review.pause_confirm", value: "暂停", comment: "暂停按钮")
        public static let pauseMessage = NSLocalizedString("review.pause_message", value: "当前进度将保存，您可以稍后继续。", comment: "暂停提示")

        // 功能提示
        public static let tooltipTitle = NSLocalizedString("review.tooltip_title", value: "卡片操作", comment: "回顾提示标题")
        public static let tooltipMessage = NSLocalizedString("review.tooltip_message", value: "轻点卡片查看参考内容。左滑稍后再看，右滑确认已处理。", comment: "回顾提示内容")

        // 滑动标记
        public static let stampForgot = NSLocalizedString("review.stamp_forgot", value: "稍后", comment: "稍后标记")
        public static let stampRemember = NSLocalizedString("review.stamp_remember", value: "确认", comment: "确认标记")

        // Dashboard
        public static let pending = NSLocalizedString("review.pending", value: "待回顾", comment: "待回顾")
        public static let completed = NSLocalizedString("review.completed", value: "已确认", comment: "已确认")
        public static let todayReview = NSLocalizedString("review.today_review", value: "今日回顾", comment: "今日回顾")
        public static let cardsPending = NSLocalizedString("review.cards_pending", value: "条内容待处理", comment: "条内容待处理")
        public static let welcomeBack = NSLocalizedString("review.welcome_back", value: "开始回顾", comment: "开始回顾")
        public static let emptyHint = NSLocalizedString("review.empty_hint", value: "还没有资料，先去采集一条。", comment: "空状态提示")
        public static let excellent = NSLocalizedString("review.excellent", value: "当前没有待处理内容。", comment: "无待处理内容")
        public static let startReview = NSLocalizedString("review.start_review", value: "开始回顾", comment: "开始回顾按钮")
        public static let goRest = NSLocalizedString("review.go_rest", value: "暂无待回顾内容", comment: "暂无待回顾内容")

        public static func reviewedToday(_ count: Int) -> String {
            String(format: NSLocalizedString("review.reviewed_today", value: "今日已确认 %d 条", comment: "今日已确认条数"), count)
        }

        // 会话摘要
        public static let summaryTitle = NSLocalizedString("review.summary_title", value: "本轮完成", comment: "回顾完成标题")
        public static let summaryGood = NSLocalizedString("review.summary_good", value: "已确认", comment: "已确认")
        public static let summaryAgain = NSLocalizedString("review.summary_again", value: "需回看", comment: "需回看")
        public static let summaryDismiss = NSLocalizedString("review.summary_dismiss", value: "完成", comment: "完成按钮")

        // 鼓励语
        public static let encourageRest = NSLocalizedString("review.encourage_rest", value: "本轮没有需要处理的内容。", comment: "摘要文案-无内容")
        public static let encourageAllGood = NSLocalizedString("review.encourage_all_good", value: "本轮内容已确认。", comment: "摘要文案-全部确认")
        public static let encourageKeepGoing = NSLocalizedString("review.encourage_keep_going", value: "这些内容会按计划再次出现。", comment: "摘要文案-全部稍后")

        public static func encouragePartial(_ count: Int) -> String {
            String(format: NSLocalizedString("review.encourage_partial", value: "%d 条内容稍后会再次出现。", comment: "摘要文案-部分稍后"), count)
        }

        // SM-2 间隔描述
        public static let intervalMinutes = NSLocalizedString("review.interval_minutes", value: "10分钟", comment: "SM-2 间隔：10分钟后")
        public static let intervalTomorrow = NSLocalizedString("review.interval_tomorrow", value: "明天", comment: "SM-2 间隔：明天")
        public static func intervalDays(_ days: Int) -> String {
            String(format: NSLocalizedString("review.interval_days", value: "%d天", comment: "SM-2 间隔：N天"), days)
        }
        public static func intervalWeeks(_ weeks: Int) -> String {
            String(format: NSLocalizedString("review.interval_weeks", value: "%d周", comment: "SM-2 间隔：N周"), weeks)
        }
        public static func intervalMonths(_ months: Int) -> String {
            String(format: NSLocalizedString("review.interval_months", value: "%d个月", comment: "SM-2 间隔：N个月"), months)
        }
    }
}
