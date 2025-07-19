//
//  UserAggregateRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesUserUser // 包含 User (聚合根)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsContactEmail // 包含 Email
// import NotBadCoreDomainErrors // 包含 UserDomainError (或其他通用领域错误)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 邮箱值对象 (仅为编译目的包含，实际应从 Email.swift 导入)
struct Email: Codable, Sendable, Hashable {
    let value: String
    init(_ value: String) throws { self.value = value } // Simplified for compilation
}

/// 用户资料值对象 (仅为编译目的包含，实际应从 UserProfile.swift 导入)
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String
    let avatarURL: URL?
    let bio: String?
    let registrationDate: Date
    init(displayName: String, avatarURL: URL? = nil, bio: String? = nil, registrationDate: Date = Date()) throws { self.displayName = displayName; self.avatarURL = avatarURL; self.bio = bio; self.registrationDate = registrationDate } // Simplified for compilation
}

/// 用户偏好设置值对象 (仅为编译目的包含，实际应从 UserPreferences.swift 导入)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return Subject.allCases.first(where: { $0.rawValue == name }) }
}
struct UserPreferences: Codable, Sendable, Hashable {
    let enableNotifications: Bool
    let preferredSubject: Subject?
    init(enableNotifications: Bool = true, preferredSubject: Subject? = nil) { self.enableNotifications = enableNotifications; self.preferredSubject = preferredSubject } // Simplified for compilation
}

/// 用户领域实体 (聚合根) (仅为编译目的包含，实际应从 User.swift 导入)
struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UserID
    let email: Email
    let profile: UserProfile
    let preferences: UserPreferences
    let createdAt: Date
    let lastLoginAt: Date

    init(id: UserID = UserID(), email: Email, displayName: String, createdAt: Date = Date()) throws {
        self.id = id; self.email = email; self.profile = try UserProfile(displayName: displayName); self.preferences = UserPreferences(); self.createdAt = createdAt; self.lastLoginAt = createdAt
    }
    static func reconstruct(id: UserID, email: Email, profile: UserProfile, preferences: UserPreferences, createdAt: Date, lastLoginAt: Date) -> User {
        return User(id: id, email: email, profile: profile, preferences: preferences, createdAt: createdAt, lastLoginAt: lastLoginAt)
    }
}


/// 用户聚合仓储接口
/// 定义了对 `User` 聚合根进行持久化和检索的契约。
/// 仓储是领域层与基础设施层之间的桥梁，它以聚合根为单位进行操作。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol UserAggregateRepository: Sendable {

    /// 保存或更新一个 `User` 聚合根。
    /// 如果 `User` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter user: 要保存或更新的 `User` 聚合根实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func save(_ user: User) async throws

    /// 根据 ID 查找一个 `User` 聚合根。
    /// - Parameter id: 要查找的 `User` 的唯一标识符。
    /// - Returns: 找到的 `User` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by id: UserID) async throws -> User?

    /// 根据邮箱查找一个 `User` 聚合根。
    /// 通常用于登录或注册时检查邮箱是否已存在。
    /// - Parameter email: 要查找的 `User` 的邮箱地址。
    /// - Returns: 找到的 `User` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by email: Email) async throws -> User?

    /// 删除一个 `User` 聚合根。
    /// - Parameter user: 要删除的 `User` 聚合根实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func delete(_ user: User) async throws

    /// 获取所有 `User` 聚合根。
    /// - Returns: 包含所有 `User` 聚合根的数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func findAll() async throws -> [User]

    // 您可以根据业务需求添加更多查询方法，例如：
    // func searchUsers(searchTerm: String) async throws -> [User]
    // func countAllUsers() async throws -> Int
}

