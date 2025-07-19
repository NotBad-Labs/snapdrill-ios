//
//  UserQueries.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreApplicationQueries // 包含 Query 协议

/// 用户查询：根据ID获取用户
/// 用于通过唯一标识符获取单个用户实体。
/// 遵循 `Query` 协议。
struct GetUserByIdQuery: Query {
    let userId: UserID // 要查询的用户ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户查询：根据邮箱获取用户
/// 用于通过邮箱地址获取单个用户实体。
/// 遵循 `Query` 协议。
struct GetUserByEmailQuery: Query {
    let email: String // 要查询的邮箱地址

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户查询：获取当前登录用户资料
/// 用于获取当前已认证用户的个人资料。
/// 遵循 `Query` 协议。
struct GetCurrentUserProfileQuery: Query {
    let userId: UserID // 当前登录用户的ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户查询：获取当前登录用户偏好设置
/// 用于获取当前已认证用户的偏好设置。
/// 遵循 `Query` 协议。
struct GetCurrentUserPreferencesQuery: Query {
    let userId: UserID // 当前登录用户的ID

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户查询：搜索用户
/// 用于根据关键词搜索用户（例如按显示名称）。
/// 遵循 `Query` 协议。
struct SearchUsersQuery: Query {
    let searchTerm: String // 搜索关键词

    // Hashable 和 Equatable 协议的自动实现
}

