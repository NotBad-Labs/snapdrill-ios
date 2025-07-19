//
//  UserDomainError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 用户领域错误
/// 定义了所有与用户相关的业务逻辑错误。
/// 遵循 `Error`, `CustomStringConvertible`, `LocalizedError` 协议，
/// 以便提供清晰的错误描述和本地化支持。
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    // MARK: - 认证与注册错误
    case invalidEmailFormat // 邮箱格式不正确
    case invalidPassword // 密码无效或不符合要求
    case authenticationFailed(String) // 认证失败，包含具体原因（如密码错误、用户不存在）
    case unauthorizedAccess // 未授权的操作

    // MARK: - 用户资料与偏好设置错误
    case emptyUserName // 用户名为空
    case userNameTooLong(String) // 用户名过长
    case userNotFound // 用户不存在
    case profileUpdateFailed(String) // 用户资料更新失败，包含具体原因
    case preferencesUpdateFailed(String) // 用户偏好设置更新失败，包含具体原因

    // MARK: - 账户管理错误
    case accountDeletionFailed(String) // 账户删除失败，包含具体原因
    case passwordResetFailed(String) // 密码重置失败，包含具体原因
    case emailAlreadyInUse // 邮箱已被注册
    case weakPassword // 密码强度不足

    // MARK: - 通用用户相关错误
    case invalidUserStatus(String) // 用户状态无效，不允许当前操作
    case genericUserError(String) // 通用用户错误，包含具体消息

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .invalidEmailFormat:
            return "邮箱格式不正确。"
        case .invalidPassword:
            return "密码无效或不符合要求。"
        case .authenticationFailed(let reason):
            return "认证失败: \(reason)。"
        case .unauthorizedAccess:
            return "未授权访问此资源或操作。"
        case .emptyUserName:
            return "用户名不能为空。"
        case .userNameTooLong(let name):
            return "用户名 '\(name)' 过长，最多支持20个字符。"
        case .userNotFound:
            return "用户未找到。"
        case .profileUpdateFailed(let reason):
            return "用户资料更新失败: \(reason)。"
        case .preferencesUpdateFailed(let reason):
            return "用户偏好设置更新失败: \(reason)。"
        case .accountDeletionFailed(let reason):
            return "账户删除失败: \(reason)。"
        case .passwordResetFailed(let reason):
            return "密码重置失败: \(reason)。"
        case .emailAlreadyInUse:
            return "该邮箱已被注册，请尝试其他邮箱或直接登录。"
        case .weakPassword:
            return "密码强度不足，请使用更复杂的密码。"
        case .invalidUserStatus(let status):
            return "用户当前状态 '\(status)' 不允许执行此操作。"
        case .genericUserError(let message):
            return "发生通用用户错误: \(message)。"
        }
    }

    // MARK: - LocalizedError 协议实现
    /// 提供错误的本地化描述，用于向用户展示。
    var errorDescription: String? {
        // 在实际应用中，这里会通过本地化字符串表获取对应的本地化消息。
        // 例如：NSLocalizedString("invalidEmailFormat", comment: "邮箱格式不正确")
        return description // 暂时直接返回 description
    }
}

