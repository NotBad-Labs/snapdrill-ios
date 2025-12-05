//
//  ReviewItem+Validation.swift
//  NotBad
//
//  数据验证扩展
//
//  将验证相关的方法从 Actions 中分离，提高单一职责。
//

import Foundation

// MARK: - ReviewItem Validation

extension ReviewItem {

    /// 验证数据完整性（类型安全版本）
    ///
    /// 返回结构化的验证结果，区分错误和警告。
    ///
    /// - Returns: 验证结果对象，包含错误列表和警告列表
    func validateItem() -> ValidationResult {
        var issues: [ValidationIssue] = []

        // 必填项检查（错误）
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append(.titleRequired)
        }

        // 建议项检查（警告）
        if imageData == nil && note.isEmpty {
            issues.append(.contentSuggested)
        }

        if knowledgePoints.isEmpty {
            issues.append(.knowledgePointsSuggested)
        }

        return ValidationResult(issues: issues)
    }
    
    /// 验证数据完整性（向后兼容）
    ///
    /// - Returns: 验证结果元组，包含是否有效和问题列表
    @available(*, deprecated, message: "Use validateItem() for type-safe validation")
    func validate() -> (isValid: Bool, issues: [String]) {
        let result = validateItem()
        return (result.isValid, result.allMessages)
    }

    /// 是否数据完整
    ///
    /// 要求：
    /// - 有图片或笔记（至少一项）
    /// - 有知识点标签
    /// - 标题非空
    ///
    /// - Returns: 数据是否完整
    var isComplete: Bool {
        (hasImage || hasNote) && hasKnowledgePoints && !title.isEmpty
    }
}
