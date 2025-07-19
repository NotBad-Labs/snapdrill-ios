//
//  UserCommandHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 RegisterUserCommand 等
// import NotBadCoreApplicationHandlers // 包含 CommandHandler 协议
// import NotBadCoreDomainEntitiesUser // 包含 User (聚合根)
// import NotBadCoreDomainRepositoriesUserAggregateRepository // 包含 UserAggregateRepository 协议
// import NotBadCoreDomainErrorsUserDomainError // 包含 UserDomainError
// import NotBadCoreDomainValueObjectsContactEmail // 包含 Email
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject

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
    var localPart: String { "" } // Simplified
    var domainPart: String { "" } // Simplified
}

/// 用户资料值对象 (简化版)
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String
    let avatarURL: URL?
    let bio: String?
    let registrationDate: Date
    init(displayName: String, avatarURL: URL? = nil, bio: String? = nil, registrationDate: Date = Date()) throws {
        self.displayName = displayName; self.avatarURL = avatarURL; self.bio = bio; self.registrationDate = registrationDate
    }
    func updateDisplayName(_ newName: String) throws -> UserProfile { return self } // Simplified
    func updateAvatarURL(_ newURL: URL?) -> UserProfile { return self } // Simplified
    func updateBio(_ newBio: String?) -> UserProfile { return self } // Simplified
}

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
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
    func withNotifications(_ enabled: Bool) -> UserPreferences { return self } // Simplified
    func withPreferredSubject(_ subject: Subject?) -> UserPreferences { return self } // Simplified
    func withReviewReminderTime(_ time: Date?) -> UserPreferences { return self } // Simplified
    func withTheme(_ newTheme: String) -> UserPreferences { return self } // Simplified
    func withSoundEffects(_ enabled: Bool) -> UserPreferences { return self } // Simplified
    func withHapticFeedback(_ enabled: Bool) -> UserPreferences { return self } // Simplified
}

/// 用户领域实体 (聚合根) (简化版)
struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UserID
    let email: Email
    let profile: UserProfile
    let preferences: UserPreferences
    let createdAt: Date
    let lastLoginAt: Date
    init(id: UserID = UserID(), email: Email, displayName: String, createdAt: Date = Date()) throws {
        self.id = id; self.email = email; self.profile = try UserProfile(displayName: displayName)
        self.preferences = UserPreferences(); self.createdAt = createdAt; self.lastLoginAt = createdAt
    }
    static func reconstruct(id: UserID, email: Email, profile: UserProfile, preferences: UserPreferences, createdAt: Date, lastLoginAt: Date) -> User {
        return User(id: id, email: email, profile: profile, preferences: preferences, createdAt: createdAt, lastLoginAt: lastLoginAt)
    }
    func updateProfile(_ newProfile: UserProfile) -> User {
        return User.reconstruct(id: id, email: email, profile: newProfile, preferences: preferences, createdAt: createdAt, lastLoginAt: lastLoginAt)
    }
    func updatePreferences(_ newPreferences: UserPreferences) -> User {
        return User.reconstruct(id: id, email: email, profile: profile, preferences: newPreferences, createdAt: createdAt, lastLoginAt: lastLoginAt)
    }
    func recordLogin(at loginTime: Date) -> User {
        return User.reconstruct(id: id, email: email, profile: profile, preferences: preferences, createdAt: createdAt, lastLoginAt: loginTime)
    }
}

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 用户领域错误 (简化版)
enum UserDomainError: DomainError {
    case invalidEmailFormat
    case invalidPassword
    case emptyUserName
    case userNameTooLong(String)
    case userNotFound
    case authenticationFailed(String)
    case unauthorizedAccess
    case profileUpdateFailed(String)
    case preferencesUpdateFailed(String)
    case emailAlreadyInUse // 新增：邮箱已被注册
    case weakPassword // 新增：密码强度不足
    case accountDeletionFailed(String) // 新增：账户删除失败
    case passwordResetFailed(String) // 新增：密码重置失败

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
        case .emailAlreadyInUse:
            return "该邮箱已被注册，请尝试其他邮箱或直接登录。"
        case .weakPassword:
            return "密码强度不足，请使用更复杂的密码。"
        case .accountDeletionFailed(let reason):
            return "账户删除失败: \(reason)。"
        case .passwordResetFailed(let reason):
            return "密码重置失败: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 仓储基础协议 (简化版)
protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Codable & Hashable & Sendable
    func save(_ entity: Entity) async throws
    func find(by id: Entity.ID) async throws -> Entity?
    func delete(_ entity: Entity) async throws
}

/// 用户聚合仓储接口 (简化版)
protocol UserAggregateRepository: Repository where Entity == User {
    func find(byEmail email: Email) async throws -> User?
}

/// 命令协议 (简化版)
protocol Command: Hashable, Sendable {}

/// 命令处理器协议 (简化版)
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

/// 用户命令：用户注册 (简化版)
struct RegisterUserCommand: Command {
    let email: String
    let password: String
    let displayName: String
}

/// 用户命令：用户登录 (简化版)
struct LoginUserCommand: Command {
    let email: String
    let password: String
}

/// 用户命令：更新用户资料 (简化版)
struct UpdateUserProfileCommand: Command {
    let userId: UserID
    let newDisplayName: String?
    let newAvatarURL: URL?
    let newBio: String?
}

/// 用户命令：更新用户偏好设置 (简化版)
struct UpdateUserPreferencesCommand: Command {
    let userId: UserID
    let enableNotifications: Bool?
    let preferredSubject: Subject?
    let reviewReminderTime: Date?
    let theme: String?
    let enableSoundEffects: Bool?
    let enableHapticFeedback: Bool?
}

/// 用户命令：重置用户密码 (简化版)
struct ResetUserPasswordCommand: Command {
    let email: String
}

/// 用户命令：删除用户账户 (简化版)
struct DeleteUserAccountCommand: Command {
    let userId: UserID
    let passwordConfirmation: String
}

/// 用户命令：记录用户登录时间 (简化版)
struct RecordUserLoginCommand: Command {
    let userId: UserID
    let loginTime: Date
}


// MARK: - 用户命令处理器

/// 用户注册命令处理器
/// 负责处理 `RegisterUserCommand`，创建 `User` 聚合根并保存。
struct RegisterUserCommandHandler: CommandHandler {
    typealias C = RegisterUserCommand

    private let userRepository: UserAggregateRepository
    // 实际应用中可能需要密码加密服务
    // private let passwordHasher: PasswordHashingService

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
        // self.passwordHasher = passwordHasher // 注入密码加密服务
    }

    /// 处理 `RegisterUserCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError` 或其他持久化相关的错误。
    func handle(_ command: RegisterUserCommand) async throws {
        // 1. 验证邮箱格式（通常在 Email 值对象中完成）
        let email = try Email(command.email)

        // 2. 检查邮箱是否已被注册
        if let _ = try await userRepository.find(byEmail: email) {
            throw UserDomainError.emailAlreadyInUse
        }

        // 3. 验证密码强度（通常由领域规则或专门的服务处理）
        // if !passwordHasher.isStrongEnough(command.password) {
        //     throw UserDomainError.weakPassword
        // }
        // let hashedPassword = passwordHasher.hash(command.password) // 实际应用中需要加密密码

        // 4. 使用领域层的工厂方法或初始化器创建 User 聚合根
        let newUser = try User(
            email: email,
            displayName: command.displayName
            // passwordHash: hashedPassword // 实际应用中需要传入加密后的密码
        )

        // 5. 通过仓储保存 User 聚合根
        try await userRepository.save(newUser)

        // 6. (可选) 发布领域事件，例如 UserRegisteredEvent
        // EventBus.shared.publish(UserRegisteredEvent(userId: newUser.id))
    }
}

/// 用户登录命令处理器
/// 负责处理 `LoginUserCommand`，验证用户凭据。
struct LoginUserCommandHandler: CommandHandler {
    typealias C = LoginUserCommand

    private let userRepository: UserAggregateRepository
    // private let passwordHasher: PasswordHashingService // 实际应用中可能需要密码验证服务

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
        // self.passwordHasher = passwordHasher
    }

    /// 处理 `LoginUserCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError.authenticationFailed` 或 `UserDomainError.userNotFound`。
    func handle(_ command: LoginUserCommand) async throws {
        let email = try Email(command.email)

        // 1. 查找用户
        guard let user = try await userRepository.find(byEmail: email) else {
            throw UserDomainError.authenticationFailed("用户不存在。")
        }

        // 2. 验证密码（实际应用中需要解密并比对）
        // if !passwordHasher.verify(password: command.password, hashedPassword: user.passwordHash) {
        //     throw UserDomainError.authenticationFailed("密码不正确。")
        // }

        // 3. 记录登录时间
        let updatedUser = user.recordLogin(at: Date())
        try await userRepository.save(updatedUser)

        // 4. (可选) 发布领域事件，例如 UserLoggedInEvent
        // EventBus.shared.publish(UserLoggedInEvent(userId: user.id))
    }
}

/// 更新用户资料命令处理器
/// 负责处理 `UpdateUserProfileCommand`，更新用户的个人资料。
struct UpdateUserProfileCommandHandler: CommandHandler {
    typealias C = UpdateUserProfileCommand

    private let userRepository: UserAggregateRepository

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    /// 处理 `UpdateUserProfileCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError.userNotFound` 或 `UserDomainError.profileUpdateFailed`。
    func handle(_ command: UpdateUserProfileCommand) async throws {
        // 1. 查找用户
        guard let existingUser = try await userRepository.find(by: command.userId) else {
            throw UserDomainError.userNotFound
        }

        // 2. 构建新的 UserProfile 值对象 (基于现有数据和命令中的更新)
        var updatedProfile = existingUser.profile

        if let newDisplayName = command.newDisplayName {
            updatedProfile = try updatedProfile.updateDisplayName(newDisplayName)
        }
        if let newAvatarURL = command.newAvatarURL {
            updatedProfile = updatedProfile.updateAvatarURL(newAvatarURL)
        }
        if let newBio = command.newBio {
            updatedProfile = updatedProfile.updateBio(newBio)
        }

        // 3. 调用 User 聚合根的业务方法来更新资料
        let updatedUser = existingUser.updateProfile(updatedProfile)

        // 4. 通过仓储保存更新后的 User 聚合根
        try await userRepository.save(updatedUser)

        // 5. (可选) 发布领域事件，例如 UserProfileUpdatedEvent
        // EventBus.shared.publish(UserProfileUpdatedEvent(userId: command.userId))
    }
}

/// 更新用户偏好设置命令处理器
/// 负责处理 `UpdateUserPreferencesCommand`，更新用户的个性化偏好。
struct UpdateUserPreferencesCommandHandler: CommandHandler {
    typealias C = UpdateUserPreferencesCommand

    private let userRepository: UserAggregateRepository

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    /// 处理 `UpdateUserPreferencesCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError.userNotFound` 或 `UserDomainError.preferencesUpdateFailed`。
    func handle(_ command: UpdateUserPreferencesCommand) async throws {
        // 1. 查找用户
        guard let existingUser = try await userRepository.find(by: command.userId) else {
            throw UserDomainError.userNotFound
        }

        // 2. 构建新的 UserPreferences 值对象 (基于现有数据和命令中的更新)
        var updatedPreferences = existingUser.preferences

        if let enableNotifications = command.enableNotifications {
            updatedPreferences = updatedPreferences.withNotifications(enableNotifications)
        }
        if let preferredSubject = command.preferredSubject {
            updatedPreferences = updatedPreferences.withPreferredSubject(preferredSubject)
        }
        if let reviewReminderTime = command.reviewReminderTime {
            updatedPreferences = updatedPreferences.withReviewReminderTime(reviewReminderTime)
        }
        if let theme = command.theme {
            updatedPreferences = updatedPreferences.withTheme(theme)
        }
        if let enableSoundEffects = command.enableSoundEffects {
            updatedPreferences = updatedPreferences.withSoundEffects(enableSoundEffects)
        }
        if let enableHapticFeedback = command.enableHapticFeedback {
            updatedPreferences = updatedPreferences.withHapticFeedback(enableHapticFeedback)
        }

        // 3. 调用 User 聚合根的业务方法来更新偏好设置
        let updatedUser = existingUser.updatePreferences(updatedPreferences)

        // 4. 通过仓储保存更新后的 User 聚合根
        try await userRepository.save(updatedUser)

        // 5. (可选) 发布领域事件，例如 UserPreferencesUpdatedEvent
        // EventBus.shared.publish(UserPreferencesUpdatedEvent(userId: command.userId))
    }
}

/// 重置用户密码命令处理器
/// 负责处理 `ResetUserPasswordCommand`，触发密码重置流程。
struct ResetUserPasswordCommandHandler: CommandHandler {
    typealias C = ResetUserPasswordCommand

    private let userRepository: UserAggregateRepository
    // private let authService: AuthenticationService // 实际应用中可能需要认证服务来发送重置邮件

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
        // self.authService = authService
    }

    /// 处理 `ResetUserPasswordCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError.passwordResetFailed` 或 `UserDomainError.userNotFound`。
    func handle(_ command: ResetUserPasswordCommand) async throws {
        let email = try Email(command.email)

        // 1. 查找用户，确保用户存在
        guard let _ = try await userRepository.find(byEmail: email) else {
            throw UserDomainError.userNotFound // 或者更通用的错误，避免泄露用户是否存在
        }

        // 2. 调用认证服务触发密码重置流程（例如发送重置邮件）
        // try await authService.sendPasswordResetEmail(to: email)

        // 3. (可选) 发布领域事件，例如 PasswordResetRequestedEvent
        // EventBus.shared.publish(PasswordResetRequestedEvent(email: command.email))
    }
}

/// 删除用户账户命令处理器
/// 负责处理 `DeleteUserAccountCommand`，删除用户账户及其相关数据。
struct DeleteUserAccountCommandHandler: CommandHandler {
    typealias C = DeleteUserAccountCommand

    private let userRepository: UserAggregateRepository
    // private let authService: AuthenticationService // 实际应用中可能需要认证服务来重新认证用户
    // private let dataCleanupService: DataCleanupService // 清理用户相关数据的服务

    /// 初始化命令处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
        // self.authService = authService
        // self.dataCleanupService = dataCleanupService
    }

    /// 处理 `DeleteUserAccountCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `UserDomainError.accountDeletionFailed` 或 `UserDomainError.userNotFound`。
    func handle(_ command: DeleteUserAccountCommand) async throws {
        // 1. 查找用户
        guard let userToDelete = try await userRepository.find(by: command.userId) else {
            throw UserDomainError.userNotFound
        }

        // 2. 重新认证用户（通常需要用户再次输入密码）
        // try await authService.reauthenticate(userId: command.userId, password: command.passwordConfirmation)

        // 3. 通过仓储删除 User 聚合根
        try await userRepository.delete(userToDelete)

        // 4. 清理用户相关的所有数据（学习记录、题目、偏好等）
        // try await dataCleanupService.cleanupUserData(for: command.userId)

        // 5. (可选) 发布领域事件，例如 UserAccountDeletedEvent
        // EventBus.shared.publish(UserAccountDeletedEvent(userId: command.userId))
    }
}

/// 记录用户登录时间命令处理器
/// 负责处理 `RecordUserLoginCommand`，更新用户的最后登录时间。
struct RecordUserLoginCommandHandler: CommandHandler {
    typealias C = RecordUserLoginCommand

    private let userRepository: UserAggregateRepository

    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    func handle(_ command: RecordUserLoginCommand) async throws {
        // 1. 查找用户
        guard let existingUser = try await userRepository.find(by: command.userId) else {
            throw UserDomainError.userNotFound
        }

        // 2. 调用 User 聚合根的业务方法来更新最后登录时间
        let updatedUser = existingUser.recordLogin(at: command.loginTime)

        // 3. 通过仓储保存更新后的 User 聚合根
        try await userRepository.save(updatedUser)
    }
}

