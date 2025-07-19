//
//  User.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsContactEmail // 包含 Email
// import NotBadCoreDomainEntitiesUserUserProfile // 包含 UserProfile
// import NotBadCoreDomainEntitiesUserUserPreferences // 包含 UserPreferences
// import NotBadCoreDomainErrors // 包含 UserDomainError

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 邮箱值对象 (仅为编译目的包含，实际应从 Email.swift 导入)
struct Email: Codable, Sendable, Hashable {
    let value: String
    init(_ value: String) throws {
        // 简单的邮箱格式验证，实际应更严格
        guard value.contains("@") && value.contains(".") else {
            throw UserDomainError.invalidEmailFormat
        }
        self.value = value
    }
}

/// 用户资料值对象 (仅为编译目的包含，实际应从 UserProfile.swift 导入)
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String
    let avatarURL: URL?
    let bio: String?
    let registrationDate: Date

    init(displayName: String, avatarURL: URL? = nil, bio: String? = nil, registrationDate: Date = Date()) throws {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw UserDomainError.emptyUserName
        }
        guard trimmedName.count <= 20 else { // 示例：显示名称长度限制
            throw UserDomainError.userNameTooLong(trimmedName)
        }
        self.displayName = trimmedName
        self.avatarURL = avatarURL
        self.bio = bio
        self.registrationDate = registrationDate
    }

    /// 更新显示名称
    func updateDisplayName(_ newName: String) throws -> UserProfile {
        return try UserProfile(displayName: newName, avatarURL: avatarURL, bio: bio, registrationDate: registrationDate)
    }

    /// 更新头像URL
    func updateAvatarURL(_ newURL: URL?) -> UserProfile {
        return try! UserProfile(displayName: displayName, avatarURL: newURL, bio: bio, registrationDate: registrationDate)
    }

    /// 更新个人简介
    func updateBio(_ newBio: String?) -> UserProfile {
        return try! UserProfile(displayName: displayName, avatarURL: avatarURL, bio: newBio, registrationDate: registrationDate)
    }
}

/// 用户偏好设置值对象 (仅为编译目的包含，实际应从 UserPreferences.swift 导入)
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

struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool
    let preferredSubject: Subject? // 用户偏好的学习学科
    let reviewReminderTime: Date? // 复习提醒时间
    let theme: String // 应用主题，例如 "light", "dark"
    let enableSoundEffects: Bool // 是否启用音效
    let enableHapticFeedback: Bool // 是否启用触觉反馈

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

    /// 返回一个带有新通知设置的新 UserPreferences 实例
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

    /// 返回一个带有新偏好学科的新 UserPreferences 实例
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

    /// 返回一个带有新复习提醒时间的新 UserPreferences 实例
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

    /// 返回一个带有新主题的新 UserPreferences 实例
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

    /// 返回一个带有新音效设置的新 UserPreferences 实例
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

    /// 返回一个带有新触觉反馈设置的新 UserPreferences 实例
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

/// 用户领域错误 (仅为编译目的包含，实际应从 UserDomainError.swift 导入)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidEmailFormat
    case invalidPassword
    case emptyUserName
    case userNameTooLong(String)
    case userNotFound
    case authenticationFailed(String)
    case unauthorizedAccess
    case profileUpdateFailed(String)
    case preferencesUpdateFailed(String)

    var description: String {
        switch self {
        case .invalidEmailFormat:
            return "邮箱格式不正确。"
        case .invalidPassword:
            return "密码无效。"
        case .emptyUserName:
            return "用户名不能为空。"
        case .userNameTooLong(let name):
            return "用户名太长: '\(name)'（最多20个字符）。"
        case .userNotFound:
            return "用户未找到。"
        case .authenticationFailed(let reason):
            return "认证失败: \(reason)。"
        case .unauthorizedAccess:
            return "未授权访问。"
        case .profileUpdateFailed(let reason):
            return "用户资料更新失败: \(reason)。"
        case .preferencesUpdateFailed(let reason):
            return "用户偏好设置更新失败: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 用户领域实体 (聚合根)
/// 代表系统中的一个用户，封装了用户的核心身份、资料和偏好设置。
/// 这是一个聚合根，它维护用户内部数据的一致性，并作为对用户操作的唯一入口。
struct User: Identifiable, Hashable, Codable, Sendable {

    // MARK: - 聚合根标识
    let id: UserID // 用户的唯一标识符

    // MARK: - 核心业务数据（高内聚）
    let email: Email // 用户的邮箱（不可变，核心身份）
    private(set) var profile: UserProfile // 用户的个人资料（可变，但通过业务方法修改）
    private(set) var preferences: UserPreferences // 用户的偏好设置（可变，但通过业务方法修改）
    let createdAt: Date // 用户创建时间
    private(set) var lastLoginAt: Date // 上次登录时间（可变，通过业务方法修改）

    // MARK: - 聚合根初始化
    /// 创建新用户（聚合根工厂方法）
    /// - Parameters:
    ///   - id: 用户ID，默认为新的UserID
    ///   - email: 用户邮箱
    ///   - displayName: 用户显示名称
    ///   - createdAt: 创建时间，默认为当前时间
    /// - Throws: UserDomainError 如果邮箱或显示名称无效
    init(
        id: UserID = UserID(),
        email: Email,
        displayName: String,
        createdAt: Date = Date()
    ) throws {
        self.id = id
        self.email = email
        self.profile = try UserProfile(displayName: displayName) // UserProfile 内部有验证
        self.preferences = UserPreferences() // 初始偏好设置
        self.createdAt = createdAt
        self.lastLoginAt = createdAt // 首次创建时，上次登录时间与创建时间相同
    }

    /// 重建聚合（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用。
    /// 它不进行业务验证，因为假定从持久化存储中读取的数据是有效的。
    static func reconstruct(
        id: UserID,
        email: Email,
        profile: UserProfile,
        preferences: UserPreferences,
        createdAt: Date,
        lastLoginAt: Date
    ) -> User {
        return User(
            id: id,
            email: email,
            profile: profile,
            preferences: preferences,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }
}

// MARK: - 聚合根核心业务行为（高内聚）
extension User {

    /// 更新用户资料
    /// - Parameter newProfile: 新的用户资料值对象
    /// - Returns: 更新后的 User 聚合根新实例
    /// - Throws: UserDomainError 如果新资料无效
    func updateProfile(_ newProfile: UserProfile) throws -> User {
        // 在这里可以添加业务规则，例如：
        // if newProfile.displayName.containsForbiddenWords() {
        //     throw UserDomainError.profileUpdateFailed("显示名称包含禁用词汇。")
        // }
        return User(
            id: id,
            email: email,
            profile: newProfile, // 使用新的资料
            preferences: preferences,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }

    /// 更新用户偏好设置
    /// - Parameter newPreferences: 新的用户偏好设置值对象
    /// - Returns: 更新后的 User 聚合根新实例
    func updatePreferences(_ newPreferences: UserPreferences) -> User {
        return User(
            id: id,
            email: email,
            profile: profile,
            preferences: newPreferences, // 使用新的偏好设置
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }

    /// 记录用户登录时间
    /// - Parameter loginTime: 登录时间，默认为当前时间
    /// - Returns: 更新后的 User 聚合根新实例
    func recordLogin(at loginTime: Date = Date()) -> User {
        return User(
            id: id,
            email: email,
            profile: profile,
            preferences: preferences,
            createdAt: createdAt,
            lastLoginAt: loginTime // 更新上次登录时间
        )
    }

    // 您可以根据业务需求添加更多与用户相关的业务行为，例如：
    // func changePassword(oldPassword: String, newPassword: String) throws -> User
    // func deactivateAccount() -> User
    // func addStudyPlan(_ plan: StudyPlan) -> User // 如果 StudyPlan 是 User 聚合的一部分
}

// MARK: - 聚合根查询接口（读取封装）
extension User {

    /// 用户显示名称
    var displayName: String { profile.displayName }

    /// 用户头像URL
    var avatarURL: URL? { profile.avatarURL }

    /// 用户个人简介
    var bio: String? { profile.bio }

    /// 用户注册日期
    var registrationDate: Date { profile.registrationDate }

    /// 是否启用通知
    var enableNotifications: Bool { preferences.enableNotifications }

    /// 用户偏好的学习学科
    var preferredSubject: Subject? { preferences.preferredSubject }

    /// 复习提醒时间
    var reviewReminderTime: Date? { preferences.reviewReminderTime }

    /// 应用主题
    var theme: String { preferences.theme }

    /// 是否启用音效
    var enableSoundEffects: Bool { preferences.enableSoundEffects }

    /// 是否启用触觉反馈
    var enableHapticFeedback: Bool { preferences.enableHapticFeedback }
}

// MARK: - 协议遵循 (Codable, Equatable, Hashable, Sendable)
extension User: Codable { } // User的所有属性都已是Codable，所以User也自动符合

// Equatable 和 Hashable 协议的实现，基于 id 属性，确保唯一性
extension User {
    static func == (lhs: User, rhs: User) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data for Testing
extension User {
    static func sample() -> User {
        return try! User(
            email: try Email("testuser@example.com"),
            displayName: "测试用户"
        )
    }

    static func anotherSample() -> User {
        return try! User(
            email: try Email("another.user@example.com"),
            displayName: "另一位用户"
        )
    }
}

