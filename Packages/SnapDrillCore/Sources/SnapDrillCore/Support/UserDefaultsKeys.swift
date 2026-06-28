//
//  UserDefaultsKeys.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UserDefaults / @AppStorage 键名集中管理，消除魔法字符串。
//

import Foundation

/// 全局 UserDefaults 键名常量，所有模块统一引用。
///
/// 使用方式：
/// ```swift
/// @AppStorage(UDKey.userName) var userName = L10n.Dashboard.defaultName
/// TelemetryGate.isGranted
/// ```
nonisolated public enum UDKey {

    // MARK: - User Profile

    public static let userName = "userName"
    public static let userAvatar = "userAvatar"
    public static let userAvatarColorIndex = "userAvatarColorIndex"
    public static let userMotto = "userMotto"

    // MARK: - Appearance

    public static let appearanceMode = "appearanceMode"
    public static let appTintColor = "appTintColor"

    // MARK: - Review Card Appearance

    public static let cardFrontAlignment = "cardFrontAlignment"
    public static let cardFrontFontSize = "cardFrontFontSize"
    public static let cardContextAlignment = "cardContextAlignment"
    public static let cardContextFontSize = "cardContextFontSize"

    // MARK: - Capture Field Visibility

    public static let captureFieldCategory = "captureFieldCategory"
    public static let captureFieldSource = "captureFieldSource"
    public static let captureFieldLevel = "captureFieldLevel"
    public static let captureFieldAnswer = "captureFieldAnswer"

    // MARK: - Last Selection (Auto-suggestion)

    public static let lastSelectedCategory = "lastSelectedCategory"
    public static let lastSelectedSource = "lastSelectedSource"

    // MARK: - Feature Flags

    public static let telemetryConsent = "telemetryConsent"
    public static let analyticsEnabled = "analyticsEnabled"
    public static let analyticsConfigured = "analyticsConfigured"
    public static let crashReportingEnabled = "crashReportingEnabled"

    // MARK: - Review Settings

    public static let dailyReviewGoal = "dailyReviewGoal"
    public static let reviewReminderEnabled = "reviewReminderEnabled"
    public static let reviewReminderTime = "reviewReminderTime"

    // MARK: - Notification Settings

    public static let notificationsEnabled = "notificationsEnabled"
    public static let notificationHour = "notificationHour"
    public static let notificationMinute = "notificationMinute"
    public static let soundEnabled = "soundEnabled"

    // MARK: - Draft Service

    public static let captureDraftMetadata = "capture_draft_metadata"

    // MARK: - Profile

    /// 当前活跃的 Profile ID（UUID 字符串）
    public static let activeProfileId = "activeProfileId"

    // MARK: - Onboarding

    public static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 功能提示前缀，实际 key 为 `hasShownTooltip_\(feature)`
    public static let hasShownTooltipPrefix = "hasShownTooltip_"

    // MARK: - Profile-level Tip State

    /// 复习滑动手势提示是否已展示（per-profile 隔离）
    public static let tipReviewSwipeSeen = "tip.reviewSwipe.v1.seen"
    /// 字段配置引导提示是否已展示（per-profile 隔离）
    public static let tipFieldConfigSeen = "tip.fieldConfig.v1.seen"

}
