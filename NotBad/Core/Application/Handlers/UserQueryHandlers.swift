//
//  UserQueryHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationQueries // 包含 GetUserByIdQuery 等
// import NotBadCoreApplicationHandlers // 包含 QueryHandler 协议
// import NotBadCoreDomainEntitiesUser // 包含 User (聚合根)
// import NotBadCoreDomainRepositoriesUserAggregateRepository // 包含 UserAggregateRepository 协议
// import NotBadCoreDomainErrorsUserDomainError // 包含 UserDomainError
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsContactEmail // 包含 Email

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
}

/// 用户偏好设置值对象 (简化版)
struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool
    let preferredSubject: Subject? // Assuming Subject is defined elsewhere
    let reviewReminderTime: Date?
    let theme: String
    let enableSoundEffects: Bool
    let enableHapticFeedback: Bool
    init(enableNotifications: Bool = true, preferredSubject: Subject? = nil, reviewReminderTime: Date? = nil, theme: String = "light", enableSoundEffects: Bool = true, enableHapticFeedback: Bool = true) {
        self.enableNotifications = enableNotifications; self.preferredSubject = preferredSubject; self.reviewReminderTime = reviewReminderTime; self.theme = theme; self.enableSoundEffects = enableSoundEffects; self.enableHapticFeedback = enableHapticFeedback
    }
}

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
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
}

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 用户领域错误 (简化版)
enum UserDomainError: DomainError {
    case userNotFound
    case invalidEmailFormat
    case genericError(String)

    var description: String {
        switch self {
        case .userNotFound: return "用户未找到。"
        case .invalidEmailFormat: return "邮箱格式不正确。"
        case .genericError(let message): return "用户相关错误: \(message)。"
        }
    }
    var errorDescription: String? { return description }
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
    func findAll() async throws -> [User] // Add findAll for search
}

/// 查询协议 (简化版)
protocol Query: Hashable, Sendable {}

/// 查询处理器协议 (简化版)
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query
    associatedtype R
    func handle(_ query: Q) async throws -> R
}

/// 用户查询：根据ID获取用户 (简化版)
struct GetUserByIdQuery: Query {
    let userId: UserID
}

/// 用户查询：根据邮箱获取用户 (简化版)
struct GetUserByEmailQuery: Query {
    let email: String
}

/// 用户查询：获取当前登录用户资料 (简化版)
struct GetCurrentUserProfileQuery: Query {
    let userId: UserID
}

/// 用户查询：获取当前登录用户偏好设置 (简化版)
struct GetCurrentUserPreferencesQuery: Query {
    let userId: UserID
}

/// 用户查询：搜索用户 (简化版)
struct SearchUsersQuery: Query {
    let searchTerm: String
}


// MARK: - 用户查询处理器

/// 根据ID获取用户查询处理器
/// 负责处理 `GetUserByIdQuery`，从仓储中获取单个用户。
struct GetUserByIdQueryHandler: QueryHandler {
    typealias Q = GetUserByIdQuery
    typealias R = User? // 返回可选的 User 聚合根

    private let userRepository: UserAggregateRepository // 依赖注入仓储

    /// 初始化查询处理器
    /// - Parameter userRepository: 用户聚合仓储的实例。
    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    /// 处理 `GetUserByIdQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `User` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetUserByIdQuery) async throws -> User? {
        return try await userRepository.find(by: query.userId)
    }
}

/// 根据邮箱获取用户查询处理器
/// 负责处理 `GetUserByEmailQuery`，从仓储中获取单个用户。
struct GetUserByEmailQueryHandler: QueryHandler {
    typealias Q = GetUserByEmailQuery
    typealias R = User?

    private let userRepository: UserAggregateRepository

    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    func handle(_ query: GetUserByEmailQuery) async throws -> User? {
        let email = try Email(query.email) // 验证邮箱格式
        return try await userRepository.find(byEmail: email)
    }
}

/// 获取当前登录用户资料查询处理器
/// 负责处理 `GetCurrentUserProfileQuery`，获取当前用户的个人资料。
struct GetCurrentUserProfileQueryHandler: QueryHandler {
    typealias Q = GetCurrentUserProfileQuery
    typealias R = UserProfile?

    private let userRepository: UserAggregateRepository

    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    func handle(_ query: GetCurrentUserProfileQuery) async throws -> UserProfile? {
        guard let user = try await userRepository.find(by: query.userId) else {
            throw UserDomainError.userNotFound // 或者返回 nil，取决于业务需求
        }
        return user.profile
    }
}

/// 获取当前登录用户偏好设置查询处理器
/// 负责处理 `GetCurrentUserPreferencesQuery`，获取当前用户的偏好设置。
struct GetCurrentUserPreferencesQueryHandler: QueryHandler {
    typealias Q = GetCurrentUserPreferencesQuery
    typealias R = UserPreferences?

    private let userRepository: UserAggregateRepository

    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    func handle(_ query: GetCurrentUserPreferencesQuery) async throws -> UserPreferences? {
        guard let user = try await userRepository.find(by: query.userId) else {
            throw UserDomainError.userNotFound // 或者返回 nil
        }
        return user.preferences
    }
}

/// 搜索用户查询处理器
/// 负责处理 `SearchUsersQuery`，根据搜索词筛选用户。
struct SearchUsersQueryHandler: QueryHandler {
    typealias Q = SearchUsersQuery
    typealias R = [User]

    private let userRepository: UserAggregateRepository

    init(userRepository: UserAggregateRepository) {
        self.userRepository = userRepository
    }

    func handle(_ query: SearchUsersQuery) async throws -> [User] {
        // 1. 获取所有用户（或通过仓储进行更优化的搜索）
        var users = try await userRepository.findAll()

        // 2. 应用搜索词过滤
        if !query.searchTerm.isEmpty {
            let lowercasedSearchTerm = query.searchTerm.lowercased()
            users = users.filter { user in
                user.profile.displayName.lowercased().contains(lowercasedSearchTerm) ||
                user.email.value.lowercased().contains(lowercasedSearchTerm) ||
                user.profile.bio?.lowercased().contains(lowercasedSearchTerm) ?? false
            }
        }

        return users
    }
}

