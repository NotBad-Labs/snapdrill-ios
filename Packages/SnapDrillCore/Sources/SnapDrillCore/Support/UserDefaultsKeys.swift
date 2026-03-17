//
//  UserDefaultsKeys.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/03/10.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  UserDefaults / @AppStorage 键名集中管理，消除魔法字符串。
//

import Foundation

/// 全局 UserDefaults 键名常量，所有模块统一引用。
///
/// 使用方式：
/// ```swift
/// @AppStorage(UDKey.userName) var userName = "同学"
/// UserDefaults.standard.bool(forKey: UDKey.analyticsEnabled)
/// ```
public enum UDKey {

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

    public static let captureFieldSubject = "captureFieldSubject"
    public static let captureFieldSource = "captureFieldSource"
    public static let captureFieldDifficulty = "captureFieldDifficulty"
    public static let captureFieldGrade = "captureFieldGrade"
    public static let captureFieldAnswer = "captureFieldAnswer"

    // MARK: - Last Selection (Auto-suggestion)

    public static let lastSelectedSubject = "lastSelectedSubject"
    public static let lastSelectedSource = "lastSelectedSource"

    // MARK: - Feature Flags

    public static let analyticsEnabled = "analyticsEnabled"
    public static let analyticsConfigured = "analyticsConfigured"
    public static let crashReportingEnabled = "crashReportingEnabled"
    public static let iCloudSyncEnabled = "iCloudSyncEnabled"

    // MARK: - Review Settings

    public static let dailyReviewGoal = "dailyReviewGoal"
    public static let reviewReminderEnabled = "reviewReminderEnabled"
    public static let reviewReminderTime = "reviewReminderTime"

    // MARK: - Notification Settings

    public static let notificationsEnabled = "notificationsEnabled"
    public static let notificationHour = "notificationHour"
    public static let notificationMinute = "notificationMinute"
    public static let soundEnabled = "soundEnabled"
    public static let badgeEnabled = "badgeEnabled"

    // MARK: - Data & Sync

    public static let autoDeleteOldItems = "autoDeleteOldItems"
    public static let autoDeleteDays = "autoDeleteDays"

    // MARK: - Privacy

    public static let privacyConsentRequested = "privacyConsentRequested"

    // MARK: - Draft Service

    public static let captureDraftMetadata = "capture_draft_metadata"

    // MARK: - Onboarding

    public static let hasCompletedOnboarding = "hasCompletedOnboarding"
    /// 功能提示前缀，实际 key 为 `hasShownTooltip_\(feature)`
    public static let hasShownTooltipPrefix = "hasShownTooltip_"

}
