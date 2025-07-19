//
//  AuthenticationUseCase.swift
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

/// 邮箱值对象 (简化版)
struct Email: Codable, Sendable, Hashable {
    let value: String
    init(_ value: String) throws { self.value = value }
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
    let email: Email
    private let profile: UserProfile
    private let preferences: UserPreferences
    init(id: UserID = UserID(), email: Email, profile: UserProfile, preferences: UserPreferences = UserPreferences()) { self.id = id; self.email = email; self.profile = profile; self.preferences = preferences }
    static func reconstruct(id: UserID, email: Email, profile: UserProfile, preferences: UserPreferences) -> User { return User(id: id, email: email, profile: profile, preferences: preferences) }
    func updateProfile(_ newProfile: UserProfile) -> User { return self }
    func updatePreferences(_ newPreferences: UserPreferences) -> User { return self }
    var userProfile: UserProfile { profile }
    var userPreferences: UserPreferences { preferences }
}

/// 用户领域错误 (简化版)
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
        case .invalidEmailFormat: return "邮箱格式不正确。"
        case .invalidPassword: return "密码无效。"
        case .emptyUserName: return "用户名不能为空。"
        case .userNameTooLong(let name): return "用户名太长: '\(name)'（最多20个字符）。"
        case .userNotFound: return "用户未找到。"
        case .authenticationFailed(let reason): return "认证失败: \(reason)。"
        case .unauthorizedAccess: return "未授权访问。"
        case .profileUpdateFailed(let reason): return "用户资料更新失败: \(reason)。"
        case .preferencesUpdateFailed(let reason): return "用户偏好设置更新失败: \(reason)。"
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


/// 认证用例接口
/// 定义了与用户认证和账户管理相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol AuthenticationUseCase: Sendable {

    /// 注册一个新用户。
    /// - Parameters:
    ///   - email: 用户邮箱。
    ///   - password: 用户密码。
    ///   - displayName: 用户显示名称。
    /// - Returns: 新注册用户的 ID。
    /// - Throws: `UserDomainError` 如果注册数据无效（如邮箱格式、密码强度、用户名冲突），
    ///           或任何其他认证服务相关的错误。
    func registerUser(email: String, password: String, displayName: String) async throws -> UserID

    /// 用户登录。
    /// - Parameters:
    ///   - email: 用户邮箱。
    ///   - password: 用户密码。
    /// - Returns: 登录成功后用户的 ID。
    /// - Throws: `UserDomainError.authenticationFailed` 如果认证失败（如密码错误、用户不存在），
    ///           或任何其他认证服务相关的错误。
    func loginUser(email: String, password: String) async throws -> UserID

    /// 用户登出。
    /// - Throws: 登出过程中可能发生的任何错误。
    func logoutUser() async throws

    /// 重置用户密码。
    /// - Parameter email: 要重置密码的邮箱。
    /// - Throws: `UserDomainError.userNotFound` 如果邮箱未注册，
    ///           或任何其他认证服务相关的错误。
    func resetPassword(for email: String) async throws

    /// 获取当前认证用户的 ID。
    /// - Returns: 当前认证用户的 UserID，如果未认证则为 `nil`。
    func getCurrentUserId() async throws -> UserID?

    /// 获取当前认证用户的完整资料 (UserProfile 和 UserPreferences)。
    /// - Returns: 当前认证用户的 `User` 聚合根实例，如果未认证则为 `nil`。
    /// - Throws: `ApplicationError.notAuthenticated` 如果用户未认证，
    ///           或任何其他查询相关的错误。
    func getCurrentUser() async throws -> User?

    /// 更新当前认证用户的资料。
    /// - Parameters:
    ///   - newDisplayName: 新的显示名称，可选。
    ///   - newAvatarURL: 新的头像 URL，可选。
    ///   - newBio: 新的个人简介，可选。
    /// - Throws: `ApplicationError.notAuthenticated` 如果用户未认证，
    ///           `UserDomainError.profileUpdateFailed` 或其他相关错误。
    func updateCurrentUserProfile(
        newDisplayName: String?,
        newAvatarURL: URL?,
        newBio: String?
    ) async throws

    /// 更新当前认证用户的偏好设置。
    /// - Parameters:
    ///   - enableNotifications: 是否启用通知，可选。
    ///   - preferredSubject: 偏好学科，可选。
    ///   - reviewReminderTime: 复习提醒时间，可选。
    ///   - theme: 应用主题，可选。
    ///   - enableSoundEffects: 是否启用音效，可选。
    ///   - enableHapticFeedback: 是否启用触觉反馈，可选。
    /// - Throws: `ApplicationError.notAuthenticated` 如果用户未认证，
    ///           `UserDomainError.preferencesUpdateFailed` 或其他相关错误。
    func updateCurrentUserPreferences(
        enableNotifications: Bool?,
        preferredSubject: Subject?,
        reviewReminderTime: Date?,
        theme: String?,
        enableSoundEffects: Bool?,
        enableHapticFeedback: Bool?
    ) async throws

    /// 删除当前认证用户的账户。
    /// - Parameter passwordConfirmation: 用于确认删除的密码。
    /// - Throws: `ApplicationError.notAuthenticated` 如果用户未认证，
    ///           `UserDomainError.authenticationFailed` 如果密码不正确，
    ///           或任何其他认证服务相关的错误。
    func deleteCurrentUserAccount(passwordConfirmation: String) async throws
}

