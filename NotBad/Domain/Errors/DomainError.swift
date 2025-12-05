//
//  DomainError.swift
//  NotBad
//
//  Domain Layer - 业务错误类型
//

import Foundation

// MARK: - DomainError

/// Domain 层错误
///
/// 表示业务规则违反，与具体实现无关。
///
/// ## 使用场景
///
/// - 业务规则验证失败
/// - 状态转换不合法
/// - 领域不变量被破坏
///
/// ## 使用示例
///
/// ```swift
/// guard item.canBeReviewed else {
///     throw DomainError.invalidStateTransition(
///         from: "completed",
///         to: "reviewing"
///     )
/// }
/// ```
enum DomainError: Error, LocalizedError, Sendable {
    
    // MARK: - Validation Errors
    
    /// 验证失败
    case validationFailed(field: String, reason: String)
    
    /// 必填字段为空
    case requiredFieldMissing(field: String)
    
    /// 值超出范围
    case valueOutOfRange(field: String, min: Any, max: Any, actual: Any)
    
    // MARK: - State Errors
    
    /// 无效的状态转换
    case invalidStateTransition(from: String, to: String)
    
    /// 操作不允许
    case operationNotAllowed(reason: String)
    
    // MARK: - Business Rule Errors
    
    /// 业务规则违反
    case businessRuleViolation(rule: String, reason: String)
    
    /// 重复实体
    case duplicateEntity(identifier: String)
    
    /// 关联实体不存在
    case relatedEntityNotFound(type: String, id: String)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let field, let reason):
            return String(localized: "\(field)验证失败：\(reason)")
            
        case .requiredFieldMissing(let field):
            return String(localized: "\(field)不能为空")
            
        case .valueOutOfRange(let field, let min, let max, let actual):
            return String(localized: "\(field)值 \(actual) 超出范围 [\(min), \(max)]")
            
        case .invalidStateTransition(let from, let to):
            return String(localized: "无法从\(from)状态切换到\(to)状态")
            
        case .operationNotAllowed(let reason):
            return String(localized: "操作不允许：\(reason)")
            
        case .businessRuleViolation(let rule, let reason):
            return String(localized: "违反业务规则「\(rule)」：\(reason)")
            
        case .duplicateEntity(let identifier):
            return String(localized: "实体已存在：\(identifier)")
            
        case .relatedEntityNotFound(let type, let id):
            return String(localized: "关联的\(type)不存在：\(id)")
        }
    }
}
