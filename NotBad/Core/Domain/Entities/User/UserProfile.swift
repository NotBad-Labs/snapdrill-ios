//
//  UserProfile.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 UserDomainError

/// 用户领域错误 (仅为编译目的包含，实际应从 UserDomainError.swift 导入)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case emptyUserName
    case userNameTooLong(String)
    case profileUpdateFailed(String)
    // Simplified for compilation
    var description: String {
        switch self {
        case .emptyUserName: return "用户名不能为空。"
        case .userNameTooLong(let name): return "用户名太长: '\(name)'（最多20个字符）。"
        case .profileUpdateFailed(let reason): return "用户资料更新失败: \(reason)。"
        default: return "未知错误。"
        }
    }
    var errorDescription: String? { return description }
}


/// 用户资料值对象
/// 封装了用户的公开个人资料信息，如显示名称、头像URL和个人简介。
/// 这是一个不可变的值对象，内部包含自验证逻辑，并提供返回新实例的修改方法。
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String // 用户显示名称
    let avatarURL: URL? // 用户头像的URL，可选
    let bio: String? // 用户个人简介，可选
    let registrationDate: Date // 用户注册日期

    /// 初始化 UserProfile
    /// - Parameters:
    ///   - displayName: 用户的显示名称
    ///   - avatarURL: 用户的头像URL，可选
    ///   - bio: 用户的个人简介，可选
    ///   - registrationDate: 用户的注册日期，默认为当前日期
    /// - Throws: UserDomainError 如果显示名称无效（例如为空或过长）
    init(
        displayName: String,
        avatarURL: URL? = nil,
        bio: String? = nil,
        registrationDate: Date = Date()
    ) throws {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证：显示名称不能为空
        guard !trimmedName.isEmpty else {
            throw UserDomainError.emptyUserName
        }
        // 验证：显示名称长度限制（示例：最多20个字符）
        guard trimmedName.count <= 20 else {
            throw UserDomainError.userNameTooLong(trimmedName)
        }

        self.displayName = trimmedName
        self.avatarURL = avatarURL
        self.bio = bio
        self.registrationDate = registrationDate
    }

    // MARK: - 业务行为 (返回新的 UserProfile 实例)

    /// 更新显示名称
    /// - Parameter newName: 新的显示名称
    /// - Returns: 带有新显示名称的 UserProfile 新实例
    /// - Throws: UserDomainError 如果新的显示名称无效
    func updateDisplayName(_ newName: String) throws -> UserProfile {
        return try UserProfile(
            displayName: newName,
            avatarURL: avatarURL,
            bio: bio,
            registrationDate: registrationDate
        )
    }

    /// 更新头像URL
    /// - Parameter newURL: 新的头像URL，nil 表示清除头像
    /// - Returns: 带有新头像URL的 UserProfile 新实例
    func updateAvatarURL(_ newURL: URL?) -> UserProfile {
        // 使用 try! 是因为这里假设内部的 displayName, bio 等在创建时已经验证过，不会再抛出错误
        // 在实际生产代码中，如果 UserProfile 的初始化器可能因为其他参数而抛出，
        // 则需要更严谨的错误处理，例如将此方法也标记为 `throws`
        return try! UserProfile(
            displayName: displayName,
            avatarURL: newURL,
            bio: bio,
            registrationDate: registrationDate
        )
    }

    /// 更新个人简介
    /// - Parameter newBio: 新的个人简介，nil 表示清除简介
    /// - Returns: 带有新个人简介的 UserProfile 新实例
    func updateBio(_ newBio: String?) -> UserProfile {
        return try! UserProfile(
            displayName: displayName,
            avatarURL: avatarURL,
            bio: newBio,
            registrationDate: registrationDate
        )
    }
}

// MARK: - Sample Data for Testing
extension UserProfile {
    static func sample() -> UserProfile {
        return try! UserProfile(
            displayName: "测试用户",
            avatarURL: URL(string: "https://example.com/avatar1.png"),
            bio: "一位热爱学习的NotBad用户。"
        )
    }

    static func anotherSample() -> UserProfile {
        return try! UserProfile(
            displayName: "学习达人",
            avatarURL: URL(string: "https://example.com/avatar2.png"),
            bio: "专注于物理和数学，每天进步一点点！"
        )
    }
}

