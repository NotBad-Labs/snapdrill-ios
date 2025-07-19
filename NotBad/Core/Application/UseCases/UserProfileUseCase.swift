//
//  UserProfileUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesUser // 包含 User (聚合根)
// import NotBadCoreDomainEntitiesUserUserProfile // 包含 UserProfile
// import NotBadCoreDomainEntitiesUserUserPreferences // 包含 UserPreferences
// import NotBadCoreDomainErrorsUserDomainError // 包含 UserDomainError
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError

/// 用户ID强类型 (简化版)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 用户资料值对象 (简化版)
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String
    let avatarURL: URL?
    let bio: String?
    let registrationDate: Date
    init(displayName: String, avatarURL: URL? = nil, bio: String? = nil, registrationDate: Date = Date()) throws { self.displayName = displayName; self.avatarURL = avatarURL; self.bio = bio; self.registrationDate = registrationDate }
    func updateDisplayName(_ newName: String) throws -> UserProfile { return self }
    func updateAvatarURL(_ newURL: URL?) -> UserProfile { return self }
    func updateBio(_ newBio: String?) -> UserProfile { return self }
}

/// 学科枚举 (简化版)
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
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 用户偏好设置值对象 (简化版)
struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool
    let preferredSubject: Subject?
    let reviewReminderTime: Date?
    let theme: String
    let enableSoundEffects: Bool
    let enableHapticFeedback: Bool
    init(enableNotifications: Bool = true, preferredSubject: Subject? = nil, reviewReminderTime: Date? = nil, theme: String = "light", enableSoundEffects: Bool = true, enableHapticFeedback: Bool = true) {
        self.enableNotifications = enableNotifications; self.preferredSubject = preferredSubject; self.reviewReminderTime = reviewReminderTime; self.theme = theme; self.enableSoundEffects = enableSoundEffects; self.enableHapticFeedback = enableHapticFeedback
    }
    func withNotifications(_ enabled: Bool) -> UserPreferences { return self }
    func withPreferredSubject(_ subject: Subject?) -> UserPreferences { return self }
    func withReviewReminderTime(_ time: Date?) -> UserPreferences { return self }
    func withTheme(_ newTheme: String) -> UserPreferences { return self }
    func withSoundEffects(_ enabled: Bool) -> UserPreferences { return self }
    func withHapticFeedback(_ enabled: Bool) -> UserPreferences { return self }
}

/// 用户聚合根 (简化版)
struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UserID
    let email: Email // Assuming Email is defined elsewhere
    private let profile: UserProfile
    private let preferences: UserPreferences
    init(id: UserID = UserID(), email: Email, profile: UserProfile, preferences: UserPreferences = UserPreferences()) { self.id = id; self.email = email; self.profile = profile; self.preferences = preferences }
    static func reconstruct(id: UserID, email: Email, profile: UserProfile, preferences: UserPreferences) -> User { return User(id: id, email: email, profile: profile, preferences: preferences) }
    func updateProfile(_ newProfile: UserProfile) -> User { return self }
    func updatePreferences(_ newPreferences: UserPreferences) -> User { return self }
    var userProfile: UserProfile { profile }
    var userPreferences: UserPreferences { preferences }
}

/// 邮箱值对象 (简化版)
struct Email: Codable, Sendable, Hashable {
    let value: String
    init(_ value: String) throws { self.value = value }
}

/// 用户领域错误 (简化版)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case userNotFound
    case profileUpdateFailed(String)
    case preferencesUpdateFailed(String)

    var description: String {
        switch self {
        case .userNotFound: return "用户未找到。"
        case .profileUpdateFailed(let reason): return "用户资料更新失败: \(reason)。"
        case .preferencesUpdateFailed(let reason): return "用户偏好设置更新失败: \(reason)。"
        default: return "未知用户领域错误。" // Added default for other cases
        }
    }
    var errorDescription: String? { return description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case notAuthenticated
    case unauthorizedAccess
    case unknownError(String)

    var description: String {
        switch self {
        case .notAuthenticated: return "用户未认证或会话已过期。"
        case .unauthorizedAccess: return "未授权访问。"
        case .unknownError(let msg): return "发生未知错误: \(msg)。"
        }
    }
    var errorDescription: String? { return description }
}


/// 用户资料用例接口
/// 定义了与用户资料和偏好设置管理相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol UserProfileUseCase: Sendable {

    /// 获取指定用户的资料。
    /// - Parameter userId: 要获取资料的用户 ID。
    /// - Returns: 用户的 `User` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限访问该用户资料，
    ///           或任何其他查询相关的错误。
    func getUserProfile(for userId: UserID) async throws -> User?

    /// 更新指定用户的资料。
    /// - Parameters:
    ///   - userId: 要更新资料的用户 ID。
    ///   - newDisplayName: 新的显示名称，可选。
    ///   - newAvatarURL: 新的头像 URL，可选。
    ///   - newBio: 新的个人简介，可选。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限修改该用户资料，
    ///           `UserDomainError.profileUpdateFailed` 或其他相关错误。
    func updateUserProfile(
        for userId: UserID,
        newDisplayName: String?,
        newAvatarURL: URL?,
        newBio: String?
    ) async throws

    /// 更新指定用户的偏好设置。
    /// - Parameters:
    ///   - userId: 要更新偏好设置的用户 ID。
    ///   - enableNotifications: 是否启用通知，可选。
    ///   - preferredSubject: 偏好学科，可选。
    ///   - reviewReminderTime: 复习提醒时间，可选。
    ///   - theme: 应用主题，可选。
    ///   - enableSoundEffects: 是否启用音效，可选。
    ///   - enableHapticFeedback: 是否启用触觉反馈，可选。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限修改该用户偏好设置，
    ///           `UserDomainError.preferencesUpdateFailed` 或其他相关错误。
    func updateUserPreferences(
        for userId: UserID,
        enableNotifications: Bool?,
        preferredSubject: Subject?,
        reviewReminderTime: Date?,
        theme: String?,
        enableSoundEffects: Bool?,
        enableHapticFeedback: Bool?
    ) async throws

    /// 获取指定用户的统计报告。
    /// - Parameter userId: 要获取报告的用户 ID。
    /// - Returns: 包含用户学习统计信息的报告（例如，总学习时间、掌握题目数量等）。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限访问该用户报告，
    ///           或任何其他查询相关的错误。
    func getUserStudyReport(for userId: UserID) async throws -> String // Simplified as String for now

    /// 导出指定用户的数据。
    /// - Parameters:
    ///   - userId: 要导出数据的用户 ID。
    ///   - fileType: 导出文件的类型（例如 "json", "csv"）。
    /// - Returns: 导出文件的本地文件 URL。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限导出该用户数据，
    ///           `InfrastructureError.fileWritingFailed` 或其他相关错误。
    func exportUserData(for userId: UserID, fileType: String) async throws -> URL
}

