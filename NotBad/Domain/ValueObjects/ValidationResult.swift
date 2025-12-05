//
//  ValidationResult.swift
//  NotBad
//
//  验证结果值对象
//

import Foundation

// MARK: - ValidationIssue

/// 验证问题类型
///
/// 类型安全的验证问题定义，替代硬编码字符串。
/// 支持本地化和严重程度分级。
enum ValidationIssue: Sendable, Equatable {
    
    // MARK: - Required Fields (Error)
    
    /// 标题为空
    case titleRequired
    
    /// 图片为空
    case imageRequired
    
    // MARK: - Suggested Fields (Warning)
    
    /// 建议添加图片或笔记
    case contentSuggested
    
    /// 建议添加知识点
    case knowledgePointsSuggested
    
    // MARK: - Properties
    
    /// 是否为必填项错误
    var isError: Bool {
        switch self {
        case .titleRequired, .imageRequired:
            return true
        case .contentSuggested, .knowledgePointsSuggested:
            return false
        }
    }
    
    /// 是否为建议性警告
    var isWarning: Bool {
        !isError
    }
    
    /// 本地化消息
    var localizedMessage: String {
        switch self {
        case .titleRequired:
            return String(localized: "validation_title_required")
        case .imageRequired:
            return String(localized: "validation_image_required")
        case .contentSuggested:
            return String(localized: "validation_content_suggested")
        case .knowledgePointsSuggested:
            return String(localized: "validation_knowledge_points_suggested")
        }
    }
}

// MARK: - ValidationResult

/// 验证结果
///
/// 封装验证结果，提供便捷的访问方法。
struct ValidationResult: Sendable {
    
    /// 所有验证问题
    let issues: [ValidationIssue]
    
    // MARK: - Computed Properties
    
    /// 是否通过验证（无错误）
    var isValid: Bool {
        errors.isEmpty
    }
    
    /// 是否完全通过（无任何问题）
    var isPerfect: Bool {
        issues.isEmpty
    }
    
    /// 所有错误
    var errors: [ValidationIssue] {
        issues.filter(\.isError)
    }
    
    /// 所有警告
    var warnings: [ValidationIssue] {
        issues.filter(\.isWarning)
    }
    
    /// 错误消息列表（向后兼容）
    var errorMessages: [String] {
        errors.map(\.localizedMessage)
    }
    
    /// 所有消息列表（向后兼容）
    var allMessages: [String] {
        issues.map(\.localizedMessage)
    }
    
    // MARK: - Factory Methods
    
    /// 创建通过的验证结果
    static let valid = ValidationResult(issues: [])
    
    /// 创建带问题的验证结果
    static func invalid(_ issues: [ValidationIssue]) -> ValidationResult {
        ValidationResult(issues: issues)
    }
}

// MARK: - ValidationResult CustomStringConvertible

extension ValidationResult: CustomStringConvertible {
    var description: String {
        if isPerfect {
            return "ValidationResult: Perfect ✓"
        } else if isValid {
            return "ValidationResult: Valid with \(warnings.count) warning(s)"
        } else {
            return "ValidationResult: Invalid with \(errors.count) error(s), \(warnings.count) warning(s)"
        }
    }
}
