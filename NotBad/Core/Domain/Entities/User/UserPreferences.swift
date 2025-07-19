//
//  UserPreferences.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case english = "英语"
    case chinese = "语文"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case computerScience = "计算机科学"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return Subject.allCases.first(where: { $0.rawValue == name }) }
}


/// 用户偏好设置值对象
/// 封装了用户的个性化偏好设置，如通知开关、偏好学科、主题等。
/// 这是一个不可变的值对象，其所有修改方法都将返回一个新的 `UserPreferences` 实例。
struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool // 是否启用通知
    let preferredSubject: Subject? // 用户偏好的学习学科，可选
    let reviewReminderTime: Date? // 复习提醒时间，可选
    let theme: String // 应用主题，例如 "light", "dark", "system"
    let enableSoundEffects: Bool // 是否启用音效
    let enableHapticFeedback: Bool // 是否启用触觉反馈

    /// 初始化 UserPreferences
    /// - Parameters:
    ///   - enableNotifications: 是否启用通知，默认为 true
    ///   - preferredSubject: 偏好的学习学科，默认为 nil
    ///   - reviewReminderTime: 复习提醒时间，默认为 nil
    ///   - theme: 应用主题，默认为 "light"
    ///   - enableSoundEffects: 是否启用音效，默认为 true
    ///   - enableHapticFeedback: 是否启用触觉反馈，默认为 true
    init(
        enableNotifications: Bool = true,
        preferredSubject: Subject? = nil,
        reviewReminderTime: Date? = nil,
        theme: String = "light",
        enableSoundEffects: Bool = true,
        enableHapticFeedback: Bool = true
    ) {
        self.enableNotifications = enableNotifications
        self.preferredSubject = preferredSubject
        self.reviewReminderTime = reviewReminderTime
        self.theme = theme
        self.enableSoundEffects = enableSoundEffects
        self.enableHapticFeedback = enableHapticFeedback
    }

    // MARK: - 业务行为 (返回新的 UserPreferences 实例)

    /// 返回一个带有新通知设置的新 UserPreferences 实例。
    /// - Parameter enabled: 是否启用通知。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withNotifications(_ enabled: Bool) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enabled,
            preferredSubject: preferredSubject,
            reviewReminderTime: reviewReminderTime,
            theme: theme,
            enableSoundEffects: enableSoundEffects,
            enableHapticFeedback: enableHapticFeedback
        )
    }

    /// 返回一个带有新偏好学科的新 UserPreferences 实例。
    /// - Parameter subject: 新的偏好学科，nil 表示清除偏好。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withPreferredSubject(_ subject: Subject?) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enableNotifications,
            preferredSubject: subject,
            reviewReminderTime: reviewReminderTime,
            theme: theme,
            enableSoundEffects: enableSoundEffects,
            enableHapticFeedback: enableHapticFeedback
        )
    }

    /// 返回一个带有新复习提醒时间的新 UserPreferences 实例。
    /// - Parameter time: 新的复习提醒时间，nil 表示清除提醒。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withReviewReminderTime(_ time: Date?) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enableNotifications,
            preferredSubject: preferredSubject,
            reviewReminderTime: time,
            theme: theme,
            enableSoundEffects: enableSoundEffects,
            enableHapticFeedback: enableHapticFeedback
        )
    }

    /// 返回一个带有新主题的新 UserPreferences 实例。
    /// - Parameter newTheme: 新的应用主题字符串。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withTheme(_ newTheme: String) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enableNotifications,
            preferredSubject: preferredSubject,
            reviewReminderTime: reviewReminderTime,
            theme: newTheme,
            enableSoundEffects: enableSoundEffects,
            enableHapticFeedback: enableHapticFeedback
        )
    }

    /// 返回一个带有新音效设置的新 UserPreferences 实例。
    /// - Parameter enabled: 是否启用音效。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withSoundEffects(_ enabled: Bool) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enableNotifications,
            preferredSubject: preferredSubject,
            reviewReminderTime: reviewReminderTime,
            theme: theme,
            enableSoundEffects: enabled,
            enableHapticFeedback: enableHapticFeedback
        )
    }

    /// 返回一个带有新触觉反馈设置的新 UserPreferences 实例。
    /// - Parameter enabled: 是否启用触觉反馈。
    /// - Returns: 更新后的 UserPreferences 实例。
    func withHapticFeedback(_ enabled: Bool) -> UserPreferences {
        return UserPreferences(
            enableNotifications: enableNotifications,
            preferredSubject: preferredSubject,
            reviewReminderTime: reviewReminderTime,
            theme: theme,
            enableSoundEffects: enableSoundEffects,
            enableHapticFeedback: enabled
        )
    }
}

// MARK: - Sample Data for Testing
extension UserPreferences {
    static func sample() -> UserPreferences {
        return UserPreferences(
            enableNotifications: true,
            preferredSubject: .mathematics,
            reviewReminderTime: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()),
            theme: "dark",
            enableSoundEffects: true,
            enableHapticFeedback: true
        )
    }

    static func anotherSample() -> UserPreferences {
        return UserPreferences(
            enableNotifications: false,
            preferredSubject: .english,
            reviewReminderTime: nil,
            theme: "light",
            enableSoundEffects: false,
            enableHapticFeedback: false
        )
    }
}

