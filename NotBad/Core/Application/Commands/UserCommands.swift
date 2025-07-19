//
//  UserCommands.swift
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
// import NotBadCoreApplicationCommands // 包含 Command 协议

/// 用户命令：用户注册
/// 用于在系统中注册一个新用户。
/// 遵循 `Command` 协议。
struct RegisterUserCommand: Command {
    let email: String // 用户邮箱
    let password: String // 用户密码
    let displayName: String // 用户显示名称

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：用户登录
/// 用于用户通过邮箱和密码登录。
/// 遵循 `Command` 协议。
struct LoginUserCommand: Command {
    let email: String // 用户邮箱
    let password: String // 用户密码

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：更新用户资料
/// 用于修改用户的公开资料（显示名称、头像URL、简介）。
/// 遵循 `Command` 协议。
struct UpdateUserProfileCommand: Command {
    let userId: UserID // 要更新的用户ID
    let newDisplayName: String? // 新的显示名称，nil 表示不修改
    let newAvatarURL: URL? // 新的头像URL，nil 表示不修改
    let newBio: String? // 新的个人简介，nil 表示不修改

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：更新用户偏好设置
/// 用于修改用户的个性化偏好（如通知、主题、偏好学科等）。
/// 遵循 `Command` 协议。
struct UpdateUserPreferencesCommand: Command {
    let userId: UserID // 要更新的用户ID
    let enableNotifications: Bool? // 是否启用通知，nil 表示不修改
    let preferredSubject: Subject? // 偏好学科，nil 表示不修改
    let reviewReminderTime: Date? // 复习提醒时间，nil 表示不修改
    let theme: String? // 应用主题，nil 表示不修改
    let enableSoundEffects: Bool? // 是否启用音效，nil 表示不修改
    let enableHapticFeedback: Bool? // 是否启用触觉反馈，nil 表示不修改

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：重置用户密码
/// 用于用户忘记密码时重置密码。
/// 遵循 `Command` 协议。
struct ResetUserPasswordCommand: Command {
    let email: String // 要重置密码的邮箱

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：删除用户账户
/// 用于用户删除自己的账户。
/// 遵循 `Command` 协议。
struct DeleteUserAccountCommand: Command {
    let userId: UserID // 要删除的用户ID
    let passwordConfirmation: String // 用于确认删除的密码

    // Hashable 和 Equatable 协议的自动实现
}

/// 用户命令：记录用户登录时间
/// 用于更新用户的最后登录时间。
/// 遵循 `Command` 协议。
struct RecordUserLoginCommand: Command {
    let userId: UserID // 登录的用户ID
    let loginTime: Date // 登录时间，默认为当前时间

    // Hashable 和 Equatable 协议的自动实现
}

