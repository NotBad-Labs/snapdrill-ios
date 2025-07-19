//
//  PhoneNumber.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrors // 包含 UserDomainError (或更通用的 DomainError)

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
    case invalidPhoneNumberFormat(String) // 新增：电话号码格式无效

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
        case .invalidPhoneNumberFormat(let number):
            return "电话号码格式无效: '\(number)'。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 电话号码值对象
/// 封装了用户的电话号码，并包含格式验证和标准化逻辑。
/// 这是一个不可变的值对象，确保电话号码的有效性和一致性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct PhoneNumber: Codable, Sendable, Hashable {
    let value: String // 标准化后的电话号码字符串（例如：+8613800138000）
    let countryCode: String // 国家代码（例如：+86）
    let nationalNumber: String // 国内号码（例如：13800138000）

    /// 初始化 PhoneNumber
    /// - Parameter rawNumber: 原始电话号码字符串，可能包含各种格式（空格、括号等）
    /// - Throws: UserDomainError 如果电话号码格式无效
    init(_ rawNumber: String) throws {
        let trimmedNumber = rawNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let digitsOnly = trimmedNumber.filter { $0.isNumber }

        // 简单的验证逻辑：假设中国大陆手机号为11位数字，且以1开头
        // 实际应用中应使用更专业的电话号码解析库（如 libPhoneNumber-iOS）进行验证和标准化
        guard digitsOnly.count == 11 && digitsOnly.hasPrefix("1") else {
            throw UserDomainError.invalidPhoneNumberFormat(rawNumber)
        }

        // 简化处理：假设所有号码都是中国大陆的手机号
        self.countryCode = "+86"
        self.nationalNumber = digitsOnly
        self.value = self.countryCode + self.nationalNumber
    }

    /// 获取不带国家代码的电话号码
    var strippedNumber: String {
        return nationalNumber
    }

    /// 获取格式化的电话号码（例如：+86 138 0013 8000）
    var formatted: String {
        // 简单的格式化，实际应更复杂
        if nationalNumber.count == 11 {
            let index3 = nationalNumber.index(nationalNumber.startIndex, offsetBy: 3)
            let index7 = nationalNumber.index(nationalNumber.startIndex, offsetBy: 7)
            return "\(countryCode) \(nationalNumber[..<index3]) \(nationalNumber[index3..<index7]) \(nationalNumber[index7...])"
        }
        return value
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension PhoneNumber: CustomStringConvertible {
    var description: String {
        return formatted
    }
}

// MARK: - Sample Data for Testing
extension PhoneNumber {
    static func sample() -> PhoneNumber {
        return try! PhoneNumber("13800138000")
    }

    static func anotherSample() -> PhoneNumber {
        return try! PhoneNumber("+86 13912345678")
    }

    static func invalidSample() -> PhoneNumber {
        return try! PhoneNumber("12345") // 这是一个无效的号码，用于测试错误处理
    }
}

