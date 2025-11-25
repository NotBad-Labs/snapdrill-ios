//
//  ErrorType.swift
//  NotBad
//
//  错误类型值对象 - 按错误根因分类
//

import SwiftUI

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
    case knowledge = "知识类"
    case method = "方法类"
    case habit = "习惯类"
    case objective = "客观类"
    case other = "其他"
    
    // MARK: Identifiable
    
    nonisolated var id: String { rawValue }
}

// MARK: - ErrorCategory Display Properties

extension ErrorCategory {
    /// 显示名称
    nonisolated var displayName: String { rawValue }
    
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
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .knowledge: .purple
        case .method: .red
        case .habit: .orange
        case .objective: .gray
        case .other: .secondary
        }
    }
    
    /// 改进方向建议
    nonisolated var improvementDirection: String {
        switch self {
        case .knowledge: "加强学习理解"
        case .method: "总结解题套路"
        case .habit: "培养良好习惯"
        case .objective: "提高做题效率"
        case .other: "具体问题具体分析"
        }
    }
}

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
    nonisolated var displayName: String { rawValue }
    
    /// 简短标签（2字）
    nonisolated var shortLabel: String {
        switch self {
        case .concept: "概念"
        case .forgotten: "遗忘"
        case .method: "方法"
        case .wrongDirection: "思路"
        case .calculation: "计算"
        case .careless: "粗心"
        case .misread: "审题"
        case .incomplete: "遗漏"
        case .timeLimit: "超时"
        case .other: "其他"
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
        switch self {
        case .concept: "回顾基础概念，理解底层原理，建立知识体系"
        case .forgotten: "定期复习，使用间隔重复法巩固记忆"
        case .method: "总结解题方法，多看例题，归纳解题模板"
        case .wrongDirection: "先分析题目考查点，再选择解题方向"
        case .calculation: "加强计算练习，养成验算习惯，使用草稿纸"
        case .careless: "做题时放慢速度，完成后检查一遍答案"
        case .misread: "仔细读题，圈出关键词，标注已知条件"
        case .incomplete: "列出完整解题步骤，逐步检查是否遗漏"
        case .timeLimit: "提高解题速度，合理分配时间，先易后难"
        case .other: "分析具体错误原因，针对性改进"
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
        case .forgotten, .wrongDirection: 4
        case .calculation, .misread: 3
        case .careless, .incomplete: 2
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
