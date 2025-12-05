//
//  ErrorCategory.swift
//  NotBad
//
//  错误分类值对象
//

import Foundation

// MARK: - ErrorCategory

/// 错误类型分类
///
/// 将错误按根本原因分为五大类别，便于分析和改进。
/// 这种分类帮助学生识别问题的本质，从而制定针对性的改进策略。
///
/// ## 分类说明
/// - ``knowledge``: 知识类 - 概念不清、知识遗忘等知识储备问题
/// - ``method``: 方法类 - 方法不当、思路错误等解题策略问题
/// - ``habit``: 习惯类 - 计算错误、粗心大意、审题失误、步骤遗漏等习惯问题
/// - ``objective``: 客观类 - 时间不足等不可控因素
/// - ``other``: 其他 - 无法明确归类的情况
///
/// ## 使用示例
/// ```swift
/// let category = ErrorCategory.knowledge
/// print(category.displayName)           // "知识类"
/// print(category.improvementDirection)  // "加强学习理解"
/// ```
enum ErrorCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case knowledge = "knowledge"
    case method = "method"
    case habit = "habit"
    case objective = "objective"
    case other = "other"

    // MARK: Identifiable

    nonisolated var id: String { rawValue }
}

// MARK: - ErrorCategory Display Properties

extension ErrorCategory {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .knowledge: "error_category_knowledge"
        case .method: "error_category_method"
        case .habit: "error_category_habit"
        case .objective: "error_category_objective"
        case .other: "error_category_other"
        }
    }

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .knowledge: "error_category_knowledge_short"
        case .method: "error_category_method_short"
        case .habit: "error_category_habit_short"
        case .objective: "error_category_objective_short"
        case .other: "error_category_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .knowledge: "brain"
        case .method: "arrow.triangle.branch"
        case .habit: "hand.raised"
        case .objective: "clock"
        case .other: "ellipsis.circle"
        }
    }

    /// 改进方向建议
    nonisolated var improvementDirection: String {
        String(localized: improvementDirectionKey)
    }

    /// 改进方向本地化键值
    private var improvementDirectionKey: String.LocalizationValue {
        switch self {
        case .knowledge: "error_category_knowledge_improvement"
        case .method: "error_category_method_improvement"
        case .habit: "error_category_habit_improvement"
        case .objective: "error_category_objective_improvement"
        case .other: "error_category_other_improvement"
        }
    }
}
