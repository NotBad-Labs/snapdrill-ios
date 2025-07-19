//
//  BusinessRuleError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrorsDomainError // 包含 DomainError

/// 业务规则错误
/// 定义了当业务逻辑规则被违反时抛出的错误。
/// 这些错误通常发生在实体或聚合根的业务方法中，表示特定操作不符合领域规则。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
enum BusinessRuleError: DomainError {
    // MARK: - 通用业务规则错误
    case ruleViolation(String) // 通用规则违反，包含具体规则描述
    case preconditionFailed(String) // 前置条件未满足，操作无法执行
    case postconditionFailed(String) // 后置条件未满足，操作结果不符合预期
    case inconsistentData(String) // 数据处于不一致状态，无法执行操作

    // MARK: - 特定业务场景示例 (可根据具体业务规则添加)
    case cannotPerformAction(String) // 无法执行特定动作，包含动作描述
    case limitExceeded(String, Int) // 超过限制，包含限制类型和限制值
    case invalidTransition(from: String, to: String) // 无效的状态转换

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .ruleViolation(let rule):
            return "业务规则违反: \(rule)。"
        case .preconditionFailed(let condition):
            return "操作前置条件未满足: \(condition)。"
        case .postconditionFailed(let condition):
            return "操作后置条件未满足: \(condition)。"
        case .inconsistentData(let context):
            return "数据处于不一致状态，无法执行操作: \(context)。"
        case .cannotPerformAction(let action):
            return "无法执行动作 '\(action)'，请检查当前业务状态。"
        case .limitExceeded(let type, let limit):
            return "\(type) 数量已达到上限 \(limit)。"
        case .invalidTransition(let from, let to):
            return "无效的状态转换：从 '\(from)' 到 '\(to)'。"
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

