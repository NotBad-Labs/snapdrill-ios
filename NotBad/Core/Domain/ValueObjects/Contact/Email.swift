//
//  Email.swift
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
    case invalidEmailFormat
    // Simplified for compilation
    var description: String {
        switch self {
        case .invalidEmailFormat: return "邮箱格式不正确。"
        }
    }
    var errorDescription: String? { return description }
}


/// 邮箱值对象
/// 封装了用户的邮箱地址。
/// 这是一个不可变的值对象，内部包含自验证逻辑，确保邮箱地址的有效性。
///
/// 遵循 `Codable`, `Hashable`, `Sendable` 协议，以支持序列化、哈希和并发安全。
struct Email: Codable, Sendable, Hashable {
    let value: String // 邮箱地址的字符串表示

    /// 初始化 Email
    /// - Parameter value: 邮箱地址字符串
    /// - Throws: UserDomainError 如果邮箱格式无效
    init(_ value: String) throws {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)

        // 验证：邮箱格式（这里使用简单的正则表达式，实际应用中应使用更复杂的验证）
        // 简单的验证：必须包含 "@" 符号，且 "@" 后面必须有 "."
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmed) else {
            throw UserDomainError.invalidEmailFormat
        }

        self.value = trimmed
    }

    // MARK: - 便捷方法

    /// 获取邮箱的域名部分
    var domain: String? {
        if let atIndex = value.firstIndex(of: "@") {
            return String(value[value.index(after: atIndex)...])
        }
        return nil
    }

    /// 获取邮箱的用户名部分
    var username: String? {
        if let atIndex = value.firstIndex(of: "@") {
            return String(value[..<atIndex])
        }
        return nil
    }

    /// 判断是否为常用邮箱服务（例如：Gmail, Outlook, QQ, 163）
    /// - Returns: true 如果是常用邮箱服务
    func isCommonEmailService() -> Bool {
        guard let domain = domain?.lowercased() else { return false }
        let commonDomains = ["gmail.com", "outlook.com", "hotmail.com", "qq.com", "163.com", "126.com", "sina.com"]
        return commonDomains.contains(domain)
    }
}

// MARK: - CustomStringConvertible (用于调试和日志)
extension Email: CustomStringConvertible {
    var description: String {
        return value
    }
}

// MARK: - Sample Data for Testing
extension Email {
    static func sample() -> Email {
        return try! Email("sample@example.com")
    }

    static func anotherSample() -> Email {
        return try! Email("another.user@gmail.com")
    }

    static func invalidSample() -> Email {
        // 这是一个无效的邮箱，用于测试错误处理
        return try! Email("invalid-email")
    }
}

