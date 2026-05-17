//
//  L10n+Review.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  L10n 复习分片：Review。
//

import Foundation

nonisolated extension L10n {

    // MARK: - Review

    public enum Review {
        public static let title = NSLocalizedString("review.title", value: "复习", comment: "复习标题")

        // 暂停弹窗
        public static let pauseAlertTitle = NSLocalizedString("review.pause_alert_title", value: "确认暂停复习？", comment: "暂停复习弹窗")
        public static let pauseContinue = NSLocalizedString("review.pause_continue", value: "继续", comment: "继续按钮")
        public static let pauseConfirm = NSLocalizedString("review.pause_confirm", value: "暂停", comment: "暂停按钮")
        public static let pauseMessage = NSLocalizedString("review.pause_message", value: "当前进度将保存，您可以稍后继续。", comment: "暂停提示")

        // 功能提示
        public static let tooltipTitle = NSLocalizedString("review.tooltip_title", value: "复习小技巧", comment: "复习提示标题")
        public static let tooltipMessage = NSLocalizedString("review.tooltip_message", value: "点击卡片翻面查看答案，左滑表示忘了，右滑表示记得", comment: "复习提示内容")

        // 滑动标记
        public static let stampForgot = NSLocalizedString("review.stamp_forgot", value: "忘记", comment: "忘记标记")
        public static let stampRemember = NSLocalizedString("review.stamp_remember", value: "记得", comment: "记得标记")

        // Dashboard
        public static let pending = NSLocalizedString("review.pending", value: "待复习", comment: "待复习")
        public static let completed = NSLocalizedString("review.completed", value: "已完成", comment: "已完成")
        public static let todayReview = NSLocalizedString("review.today_review", value: "今日复习", comment: "今日复习")
        public static let cardsPending = NSLocalizedString("review.cards_pending", value: "张卡片待处理", comment: "张卡片待处理")
        public static let welcomeBack = NSLocalizedString("review.welcome_back", value: "欢迎回来", comment: "欢迎回来")
        public static let emptyHint = NSLocalizedString("review.empty_hint", value: "还没有题目，快去录入吧！", comment: "空状态提示")
        public static let excellent = NSLocalizedString("review.excellent", value: "太棒了！", comment: "太棒了")
        public static let startReview = NSLocalizedString("review.start_review", value: "开始复习", comment: "开始复习按钮")
        public static let goRest = NSLocalizedString("review.go_rest", value: "去休息", comment: "去休息按钮")

        public static func reviewedToday(_ count: Int) -> String {
            String(format: NSLocalizedString("review.reviewed_today", value: "今日已复习 %d 张", comment: "今日已复习张数"), count)
        }

        // 会话摘要
        public static let summaryTitle = NSLocalizedString("review.summary_title", value: "今日复习完成", comment: "复习完成标题")
        public static let summaryGood = NSLocalizedString("review.summary_good", value: "掌握", comment: "掌握")
        public static let summaryAgain = NSLocalizedString("review.summary_again", value: "待加强", comment: "待加强")
        public static let summaryDismiss = NSLocalizedString("review.summary_dismiss", value: "好的", comment: "好的按钮")

        // 鼓励语
        public static let encourageRest = NSLocalizedString("review.encourage_rest", value: "休息一下，明天继续。", comment: "鼓励语-休息")
        public static let encourageAllGood = NSLocalizedString("review.encourage_all_good", value: "全部掌握，太棒了！", comment: "鼓励语-全部掌握")
        public static let encourageKeepGoing = NSLocalizedString("review.encourage_keep_going", value: "别灰心，多复习几次就记住了！", comment: "鼓励语-继续加油")

        public static func encouragePartial(_ count: Int) -> String {
            String(format: NSLocalizedString("review.encourage_partial", value: "继续加油，%d 题稍后会再出现。", comment: "鼓励语-部分掌握"), count)
        }

    }
}
