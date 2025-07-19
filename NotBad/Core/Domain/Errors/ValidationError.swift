//
//  ValidationError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrorsDomainError // 包含 DomainError

/// 验证错误
/// 定义了所有与数据输入或模型状态验证相关的错误。
/// 这些错误通常在值对象或实体创建/修改时，用于强制执行数据完整性规则。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
enum ValidationError: DomainError {
    case emptyValue(String) // 值为空，包含字段名
    case valueTooShort(String, Int) // 值太短，包含字段名和最小长度
    case valueTooLong(String, Int) // 值太长，包含字段名和最大长度
    case invalidFormat(String, String) // 格式无效，包含字段名和期望格式描述
    case outOfRange(String, Double, Double, Double) // 超出范围，包含字段名、实际值、最小值、最大值
    case negativeValue(String) // 值不能为负数，包含字段名
    case invalidCharacters(String) // 包含无效字符，包含字段名
    case duplicateValue(String) // 值重复，包含字段名
    case missingRequiredField(String) // 缺少必填字段，包含字段名
    case inconsistentState(String) // 内部状态不一致，包含具体原因
    case customValidation(String) // 自定义验证失败，包含具体原因

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .emptyValue(let field):
            return "\(field) 不能为空。"
        case .valueTooShort(let field, let min):
            return "\(field) 太短，至少需要 \(min) 个字符。"
        case .valueTooLong(let field, let max):
            return "\(field) 太长，最多允许 \(max) 个字符。"
        case .invalidFormat(let field, let format):
            return "\(field) 格式无效，应为 \(format) 形式。"
        case .outOfRange(let field, let value, let min, let max):
            return "\(field) '\(value)' 超出有效范围，必须在 \(min) 到 \(max) 之间。"
        case .negativeValue(let field):
            return "\(field) 不能为负数。"
        case .invalidCharacters(let field):
            return "\(field) 包含无效字符。"
        case .duplicateValue(let field):
            return "\(field) 已存在，请使用其他值。"
        case .missingRequiredField(let field):
            return "缺少必填字段: \(field)。"
        case .inconsistentState(let reason):
            return "内部状态不一致: \(reason)。"
        case .customValidation(let message):
            return "验证失败: \(message)。"
        }
    }

    // MARK: - LocalizedError 协议实现
    /// 提供错误的本地化描述，用于向用户展示。
    var errorDescription: String? {
        // 在实际应用中，这里会通过本地化字符串表获取对应的本地化消息。
        return description // 暂时直接返回 description
    }
}

// MARK: - 辅助协议 (为了编译，实际应从其他文件导入)
// 这些协议在实际项目中应有自己的文件，这里仅为编译目的提供简化定义。

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

