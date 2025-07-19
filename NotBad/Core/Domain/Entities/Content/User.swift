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
// import NotBadCoreDomainErrors // 包含 UserDomainError (或更通用的 DomainError)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/ValueObjects/Identity/UserID.swift
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String // 例如：Firebase Auth UID 或 UUID.uuidString
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString } // 默认生成一个UUID字符串
}

/// 邮箱值对象 (仅为编译目的包含，实际应从 Email.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/ValueObjects/Contact/Email.swift
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

/// 用户领域错误 (仅为编译目的包含，实际应从 UserDomainError.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Errors/UserDomainError.swift
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

/// 用户资料值对象 (仅为编译目的包含，实际应从 UserProfile.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/User/UserProfile.swift
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
        guard trimmedName.count <= 20 else {
            throw UserDomainError.userNameTooLong(trimmedName)
        }
        self.displayName = trimmedName
        self.avatarURL = avatarURL
        self.bio = bio
        self.registrationDate = registrationDate
    }

    func updateDisplayName(_ newName: String) throws -> UserProfile {
        return try UserProfile(displayName: newName, avatarURL: avatarURL, bio: bio, registrationDate: registrationDate)
    }

    func updateAvatarURL(_ newURL: URL?) -> UserProfile {
        return try! UserProfile(displayName: displayName, avatarURL: newURL, bio: bio, registrationDate: registrationDate)
    }

    func updateBio(_ newBio: String?) -> UserProfile {
        return try! UserProfile(displayName: displayName, avatarURL: avatarURL, bio: newBio, registrationDate: registrationDate)
    }
}

/// 用户偏好设置值对象 (仅为编译目的包含，实际应从 UserPreferences.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/User/UserPreferences.swift
struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool
    let preferredSubject: Subject? // 假设 Subject 已定义
    let reviewReminderTime: Date?
    let theme: String // 例如 "light", "dark"

    init(enableNotifications: Bool = true, preferredSubject: Subject? = nil, reviewReminderTime: Date? = nil, theme: String = "light") {
        self.enableNotifications = enableNotifications
        self.preferredSubject = preferredSubject
        self.reviewReminderTime = reviewReminderTime
        self.theme = theme
    }

    func withNotifications(_ enabled: Bool) -> UserPreferences {
        return UserPreferences(enableNotifications: enabled, preferredSubject: preferredSubject, reviewReminderTime: reviewReminderTime, theme: theme)
    }

    func withPreferredSubject(_ subject: Subject?) -> UserPreferences {
        return UserPreferences(enableNotifications: enableNotifications, preferredSubject: subject, reviewReminderTime: reviewReminderTime, theme: theme)
    }

    func withReviewReminderTime(_ time: Date?) -> UserPreferences {
        return UserPreferences(enableNotifications: enableNotifications, preferredSubject: preferredSubject, reviewReminderTime: time, theme: theme)
    }

    func withTheme(_ newTheme: String) -> UserPreferences {
        return UserPreferences(enableNotifications: enableNotifications, preferredSubject: preferredSubject, reviewReminderTime: reviewReminderTime, theme: newTheme)
    }
}

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Content/Subject.swift
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

    static func findCoreSubject(byName name: String) -> Subject? {
        return Subject.allCases.first(where: { $0.rawValue == name })
    }
}


/// 用户领域实体
/// 代表 NotBad 应用中的一个注册用户。
/// 这是一个聚合根，封装了用户的核心身份、个人资料和偏好设置，
/// 并确保这些相关数据的一致性。
struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UserID // 用户的唯一标识符 (聚合根标识)
    let email: Email // 用户的邮箱 (值对象)
    private let profile: UserProfile // 用户的个人资料 (值对象)
    private let preferences: UserPreferences // 用户的偏好设置 (值对象)
    let createdAt: Date // 用户创建时间
    private(set) var lastLoginAt: Date // 上次登录时间 (可变，但通过聚合根方法修改)

    /// 初始化 User 实体（聚合根工厂方法）
    /// 用于创建新用户。
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
        self.profile = try UserProfile(displayName: displayName) // 初始化默认资料
        self.preferences = UserPreferences() // 初始化默认偏好设置
        self.createdAt = createdAt
        self.lastLoginAt = createdAt // 首次登录时间即为创建时间
    }

    /// 重建 User 实体（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用，不进行业务验证。
    private init(
        id: UserID,
        email: Email,
        profile: UserProfile,
        preferences: UserPreferences,
        createdAt: Date,
        lastLoginAt: Date
    ) {
        self.id = id
        self.email = email
        self.profile = profile
        self.preferences = preferences
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }

    // MARK: - 聚合根业务行为

    /// 更新用户个人资料
    /// - Parameter newProfile: 新的用户资料值对象
    /// - Returns: 更新后的 User 实体新实例
    /// - Throws: UserDomainError 如果资料更新无效
    func updateProfile(_ newProfile: UserProfile) throws -> User {
        // 可以在这里添加业务规则，例如：
        // if newProfile.displayName.isEmpty { throw UserDomainError.emptyUserName }
        // ...
        return User(
            id: id,
            email: email,
            profile: newProfile,
            preferences: preferences,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }

    /// 更新用户偏好设置
    /// - Parameter newPreferences: 新的用户偏好设置值对象
    /// - Returns: 更新后的 User 实体新实例
    func updatePreferences(_ newPreferences: UserPreferences) -> User {
        return User(
            id: id,
            email: email,
            profile: profile,
            preferences: newPreferences,
            createdAt: createdAt,
            lastLoginAt: lastLoginAt
        )
    }

    /// 记录用户登录时间
    /// - Parameter loginTime: 登录时间，默认为当前时间
    /// - Returns: 更新后的 User 实体新实例
    func recordLogin(at loginTime: Date = Date()) -> User {
        var updatedUser = self
        updatedUser.lastLoginAt = loginTime // 直接修改内部可变属性
        return updatedUser
    }

    // MARK: - 聚合根查询接口

    /// 用户显示名称
    var displayName: String {
        profile.displayName
    }

    /// 用户头像URL
    var avatarURL: URL? {
        profile.avatarURL
    }

    /// 用户简介
    var bio: String? {
        profile.bio
    }

    /// 用户注册日期
    var registrationDate: Date {
        profile.registrationDate
    }

    /// 是否启用通知
    var enableNotifications: Bool {
        preferences.enableNotifications
    }

    /// 偏好学科
    var preferredSubject: Subject? {
        preferences.preferredSubject
    }

    /// 复习提醒时间
    var reviewReminderTime: Date? {
        preferences.reviewReminderTime
    }

    /// 应用主题
    var theme: String {
        preferences.theme
    }

    // MARK: - 静态工厂方法 (用于从外部数据重建或创建)

    /// 从外部数据重建 User 实体（用于Repository）
    /// - Parameters:
    ///   - id: 用户ID
    ///   - email: 邮箱
    ///   - profile: 用户资料
    ///   - preferences: 用户偏好设置
    ///   - createdAt: 创建时间
    ///   - lastLoginAt: 上次登录时间
    /// - Returns: 重建的 User 实体实例
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

