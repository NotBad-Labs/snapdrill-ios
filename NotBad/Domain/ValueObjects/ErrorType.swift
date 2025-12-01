//
//  ErrorType.swift
//  NotBad
//
//  错误类型值对象 - 按错误根因分类
//

import SwiftUI

// MARK: - ErrorType

/// 错题错误类型
///
/// 对错题的错误原因进行细分，帮助学生精准识别薄弱环节。
/// 每种错误类型都归属于一个``ErrorCategory``，并提供针对性的改进建议。
///
/// ## 错误类型分类
///
/// ### 知识类 (Knowledge)
/// - ``concept``: 概念不清 - 对知识点理解有偏差
/// - ``forgotten``: 知识遗忘 - 曾经会但忘记了
///
/// ### 方法类 (Method)
/// - ``method``: 方法不当 - 解题方法选择有问题
/// - ``wrongDirection``: 思路错误 - 解题方向不对
///
/// ### 习惯类 (Habit)
/// - ``calculation``: 计算错误 - 运算失误
/// - ``careless``: 粗心大意 - 非知识性失误
/// - ``misread``: 审题失误 - 题目理解错误
/// - ``incomplete``: 步骤遗漏 - 解题不完整
///
/// ### 客观类 (Objective)
/// - ``timeLimit``: 时间不足 - 考试时间紧张
///
/// ### 其他
/// - ``other``: 其他 - 无法明确归类
///
/// ## 使用示例
/// ```swift
/// let errorType = ErrorType.careless
/// print(errorType.category)     // .habit
/// print(errorType.suggestion)   // "做题时放慢速度..."
/// print(errorType.severity)     // 2
/// ```
enum ErrorType: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 知识类
    /// 概念不清 - 对基础概念理解有偏差
    case concept = "概念不清"
    /// 知识遗忘 - 曾经掌握但已遗忘
    case forgotten = "知识遗忘"

    // 方法类
    /// 方法不当 - 解题方法选择不合适
    case method = "方法不当"
    /// 思路错误 - 解题方向从一开始就错了
    case wrongDirection = "思路错误"

    // 习惯类
    /// 计算错误 - 运算过程中的失误
    case calculation = "计算错误"
    /// 粗心大意 - 非知识性的低级失误
    case careless = "粗心大意"
    /// 审题失误 - 题目理解或条件提取错误
    case misread = "审题失误"
    /// 步骤遗漏 - 解题过程不完整
    case incomplete = "步骤遗漏"

    // 客观类
    /// 时间不足 - 考试时间紧张导致
    case timeLimit = "时间不足"

    // 其他
    /// 其他 - 无法明确归类的错误
    case other = "其他"

    // MARK: Identifiable

    nonisolated var id: String { rawValue }
}

// MARK: - ErrorType Display Properties

extension ErrorType {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .concept: "error_type_concept"
        case .forgotten: "error_type_forgotten"
        case .method: "error_type_method"
        case .wrongDirection: "error_type_wrong_direction"
        case .calculation: "error_type_calculation"
        case .careless: "error_type_careless"
        case .misread: "error_type_misread"
        case .incomplete: "error_type_incomplete"
        case .timeLimit: "error_type_time_limit"
        case .other: "error_type_other"
        }
    }

    /// 简短标签（2字）
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .concept: "error_type_concept_short"
        case .forgotten: "error_type_forgotten_short"
        case .method: "error_type_method_short"
        case .wrongDirection: "error_type_wrong_direction_short"
        case .calculation: "error_type_calculation_short"
        case .careless: "error_type_careless_short"
        case .misread: "error_type_misread_short"
        case .incomplete: "error_type_incomplete_short"
        case .timeLimit: "error_type_time_limit_short"
        case .other: "error_type_other_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .concept: "lightbulb.slash"
        case .forgotten: "brain.head.profile"
        case .method: "arrow.triangle.branch"
        case .wrongDirection: "arrow.uturn.backward"
        case .calculation: "function"
        case .careless: "exclamationmark.triangle"
        case .misread: "eye.slash"
        case .incomplete: "checklist.unchecked"
        case .timeLimit: "clock.badge.exclamationmark"
        case .other: "questionmark.circle"
        }
    }

    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .concept: .purple
        case .forgotten: .indigo
        case .method: .red
        case .wrongDirection: .pink
        case .calculation: .blue
        case .careless: .yellow
        case .misread: .orange
        case .incomplete: .mint
        case .timeLimit: .gray
        case .other: .secondary
        }
    }
}

// MARK: - ErrorType Classification

extension ErrorType {
    /// 错误分类
    nonisolated var category: ErrorCategory {
        switch self {
        case .concept, .forgotten:
            .knowledge
        case .method, .wrongDirection:
            .method
        case .calculation, .careless, .misread, .incomplete:
            .habit
        case .timeLimit:
            .objective
        case .other:
            .other
        }
    }

    /// 获取某分类下的所有错误类型
    /// - Parameter category: 错误分类
    /// - Returns: 该分类下的错误类型数组
    static func types(in category: ErrorCategory) -> [ErrorType] {
        allCases.filter { $0.category == category }
    }
}

// MARK: - ErrorType Improvement Suggestions

extension ErrorType {
    /// 改进建议
    nonisolated var suggestion: String {
        String(localized: suggestionKey)
    }

    /// 改进建议本地化键值
    private var suggestionKey: String.LocalizationValue {
        switch self {
        case .concept: "error_type_concept_suggestion"
        case .forgotten: "error_type_forgotten_suggestion"
        case .method: "error_type_method_suggestion"
        case .wrongDirection: "error_type_wrong_direction_suggestion"
        case .calculation: "error_type_calculation_suggestion"
        case .careless: "error_type_careless_suggestion"
        case .misread: "error_type_misread_suggestion"
        case .incomplete: "error_type_incomplete_suggestion"
        case .timeLimit: "error_type_time_limit_suggestion"
        case .other: "error_type_other_suggestion"
        }
    }

    /// 是否属于主观可控错误（可通过努力改进）
    nonisolated var isControllable: Bool {
        category != .objective && self != .other
    }
}

// MARK: - ErrorType Severity

extension ErrorType {
    /// 严重程度（1-5，越高越需要重视）
    ///
    /// 严重程度基于错误对学习的影响程度：
    /// - 5: 概念性和方法性错误，影响知识体系
    /// - 4: 知识遗忘和思路错误，需要系统复习
    /// - 3: 计算和审题错误，需要加强练习
    /// - 2: 粗心和步骤遗漏，需要培养习惯
    /// - 1: 时间不足和其他，相对不可控
    nonisolated var severity: Int {
        switch self {
        case .concept, .method: 5
        case .forgotten, .wrongDirection, .misread: 4
        case .incomplete: 3
        case .calculation, .careless: 2
        case .timeLimit, .other: 1
        }
    }

    /// 复习优先级（基于严重程度）
    nonisolated var reviewPriority: Int { severity }
}

// MARK: - ErrorType Comparable

extension ErrorType: Comparable {
    nonisolated static func < (lhs: ErrorType, rhs: ErrorType) -> Bool {
        lhs.severity < rhs.severity
    }
}

// MARK: - ErrorType CustomStringConvertible

extension ErrorType: CustomStringConvertible {
    nonisolated var description: String { displayName }
}

// MARK: - ErrorType Collections

extension ErrorType {
    /// 常见错误类型（排除"其他"）
    static let commonTypes: [ErrorType] = allCases.filter { $0 != .other }

    /// 可控错误类型
    static let controllableTypes: [ErrorType] = allCases.filter { $0.isControllable }

    /// 按严重程度降序排列
    static let sortedBySeverity: [ErrorType] = allCases.sorted { $0.severity > $1.severity }

    /// 知识类错误
    static let knowledgeTypes: [ErrorType] = [.concept, .forgotten]

    /// 方法类错误
    static let methodTypes: [ErrorType] = [.method, .wrongDirection]

    /// 习惯类错误
    static let habitTypes: [ErrorType] = [.calculation, .careless, .misread, .incomplete]
}
