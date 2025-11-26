//
//  ReviewItemType.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - ReviewItemCategory

/// 题型分类
///
/// 将各种题型按评分方式和答案特点分为四大类。
///
/// ## 分类标准
///
/// - **客观题**：答案唯一，对错分明
/// - **主观题**：答案开放，按步给分
/// - **综合题**：综合能力，整体评分
/// - **其他**：不便分类的特殊题型
///
/// ## 使用示例
///
/// ```swift
/// let category = ReviewItemCategory.objective
/// print(category.displayName)  // "客观题"
/// print(category.gradingCharacteristic)  // "答案唯一，对错分明"
/// ```
enum ReviewItemCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    
    /// 客观题
    ///
    /// 包括选择、多选、判断、填空、连线等题型。
    /// 答案唯一，评分标准明确。
    case objective = "客观题"
    
    /// 主观题
    ///
    /// 包括简答、计算、证明、作图、实验、材料分析等题型。
    /// 答案开放，通常按步骤给分。
    case subjective = "主观题"
    
    /// 综合题
    ///
    /// 包括阅读理解、作文、完形填空等题型。
    /// 考察综合能力，整体评分。
    case comprehensive = "综合题"
    
    /// 其他
    ///
    /// 不便分类的特殊题型。
    case other = "其他"
    
    // MARK: - Identifiable
    
    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - ReviewItemCategory Display Properties

extension ReviewItemCategory {
    
    /// 显示名称
    nonisolated var displayName: String { rawValue }
    
    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .objective: "checkmark.square"
        case .subjective: "pencil"
        case .comprehensive: "doc.text"
        case .other: "ellipsis.circle"
        }
    }
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .objective: .blue
        case .subjective: .orange
        case .comprehensive: .purple
        case .other: .gray
        }
    }
    
    /// 评分特点描述
    nonisolated var gradingCharacteristic: String {
        switch self {
        case .objective: "答案唯一，对错分明"
        case .subjective: "答案开放，按步给分"
        case .comprehensive: "综合能力，整体评分"
        case .other: "视具体情况而定"
        }
    }
}

// MARK: - ReviewItemType

/// 错题类型（题型）
///
/// K12 教育中常见的各种题型，按分类组织。
///
/// ## 题型分布
///
/// ### 客观题（5种）
/// - 选择题、多选题、判断题、填空题、连线题
///
/// ### 主观题（6种）
/// - 简答题、计算题、证明题、作图题、实验题、材料分析
///
/// ### 综合题（3种）
/// - 阅读理解、作文、完形填空
///
/// ## 使用示例
///
/// ```swift
/// let type = ReviewItemType.calculation
/// print(type.displayName)  // "计算题"
/// print(type.category)     // .subjective
/// print(type.estimatedMinutes)  // 8
///
/// // 获取数学适用的题型
/// let mathTypes = ReviewItemType.types(for: .math)
/// ```
enum ReviewItemType: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    
    // MARK: - Objective Types (客观题)
    
    /// 选择题
    ///
    /// 单项选择，四选一最常见。
    case choice = "选择题"
    
    /// 多选题
    ///
    /// 多项选择，通常有多个正确答案。
    case multiChoice = "多选题"
    
    /// 判断题
    ///
    /// 判断对错，二选一。
    case judgment = "判断题"
    
    /// 填空题
    ///
    /// 填写空缺内容，答案通常唯一。
    case fillBlank = "填空题"
    
    /// 连线题
    ///
    /// 将相关内容进行匹配连接。
    case matching = "连线题"
    
    // MARK: - Subjective Types (主观题)
    
    /// 简答题
    ///
    /// 简要回答问题，通常有要点采分。
    case shortAnswer = "简答题"
    
    /// 计算题
    ///
    /// 需要列式计算，按步骤给分。
    case calculation = "计算题"
    
    /// 证明题
    ///
    /// 数学或物理证明，逻辑严密性要求高。
    case proof = "证明题"
    
    /// 作图题
    ///
    /// 绘制图形、图表或示意图。
    case drawing = "作图题"
    
    /// 实验题
    ///
    /// 涉及实验设计、现象描述、结论分析。
    case experiment = "实验题"
    
    /// 材料分析
    ///
    /// 根据给定材料进行分析回答。
    case analysis = "材料分析"
    
    // MARK: - Comprehensive Types (综合题)
    
    /// 阅读理解
    ///
    /// 语文或英语阅读，综合理解能力。
    case reading = "阅读理解"
    
    /// 作文
    ///
    /// 写作题，考察语言表达和组织能力。
    case writing = "作文"
    
    /// 完形填空
    ///
    /// 英语完形填空，综合语法和语境理解。
    case cloze = "完形填空"
    
    // MARK: - Other
    
    /// 其他
    ///
    /// 不便分类的特殊题型。
    case other = "其他"
    
    // MARK: - Identifiable
    
    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - ReviewItemType Display Properties

extension ReviewItemType {
    
    /// 显示名称
    nonisolated var displayName: String { rawValue }
    
    /// 简短标签（单字）
    ///
    /// 用于空间有限的 UI 展示。
    nonisolated var shortLabel: String {
        switch self {
        case .choice: "选"
        case .multiChoice: "多"
        case .judgment: "判"
        case .fillBlank: "填"
        case .matching: "连"
        case .shortAnswer: "简"
        case .calculation: "算"
        case .proof: "证"
        case .drawing: "图"
        case .experiment: "实"
        case .analysis: "析"
        case .reading: "读"
        case .writing: "写"
        case .cloze: "完"
        case .other: "他"
        }
    }
    
    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .choice: "checkmark.circle"
        case .multiChoice: "checklist"
        case .judgment: "hand.thumbsup"
        case .fillBlank: "square.and.pencil"
        case .matching: "arrow.left.arrow.right"
        case .shortAnswer: "text.alignleft"
        case .calculation: "function"
        case .proof: "arrow.right.arrow.left"
        case .drawing: "pencil.and.ruler"
        case .experiment: "flask"
        case .analysis: "doc.text.magnifyingglass"
        case .reading: "book"
        case .writing: "pencil.line"
        case .cloze: "text.badge.minus"
        case .other: "ellipsis.circle"
        }
    }
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .choice: .blue
        case .multiChoice: .indigo
        case .judgment: .cyan
        case .fillBlank: .green
        case .matching: .teal
        case .shortAnswer: .orange
        case .calculation: .red
        case .proof: .purple
        case .drawing: .pink
        case .experiment: .mint
        case .analysis: .brown
        case .reading: .yellow
        case .writing: .red
        case .cloze: .indigo
        case .other: .gray
        }
    }
}

// MARK: - ReviewItemType Category

extension ReviewItemType {
    
    /// 题型分类
    nonisolated var category: ReviewItemCategory {
        switch self {
        case .choice, .multiChoice, .judgment, .fillBlank, .matching:
            .objective
        case .shortAnswer, .calculation, .proof, .drawing, .experiment, .analysis:
            .subjective
        case .reading, .writing, .cloze:
            .comprehensive
        case .other:
            .other
        }
    }
    
    /// 是否为客观题
    ///
    /// 客观题有唯一答案，便于自动批改。
    nonisolated var isObjective: Bool { category == .objective }
    
    /// 是否为主观题
    nonisolated var isSubjective: Bool { category == .subjective }
    
    /// 是否为综合题
    nonisolated var isComprehensive: Bool { category == .comprehensive }
}

// MARK: - ReviewItemType Time & Difficulty

extension ReviewItemType {
    
    /// 预估答题时间（分钟）
    ///
    /// 基于题型的典型时间需求估算。
    nonisolated var estimatedMinutes: Int {
        switch self {
        case .choice, .judgment: 1
        case .multiChoice, .fillBlank, .matching: 2
        case .shortAnswer, .drawing: 5
        case .calculation, .experiment: 8
        case .reading: 10
        case .proof, .analysis, .cloze: 12
        case .writing: 45
        case .other: 5
        }
    }
    
    /// 预估答题时间描述
    nonisolated var estimatedTimeDescription: String {
        switch estimatedMinutes {
        case 1...2: "约 \(estimatedMinutes) 分钟"
        case 3...10: "约 \(estimatedMinutes) 分钟"
        case 11...20: "约 \(estimatedMinutes) 分钟"
        default: "约 \(estimatedMinutes) 分钟"
        }
    }
    
    /// 难度权重
    ///
    /// 综合题和主观题通常更难，权重更高：
    /// - 客观题：1.0
    /// - 主观题：1.5
    /// - 综合题：2.0
    nonisolated var difficultyWeight: Double {
        switch category {
        case .objective: 1.0
        case .subjective: 1.5
        case .comprehensive: 2.0
        case .other: 1.0
        }
    }
}

// MARK: - ReviewItemType Subject Association

extension ReviewItemType {
    
    /// 常见适用学科
    ///
    /// 返回该题型最常出现的学科列表。
    nonisolated var applicableSubjects: [Subject] {
        switch self {
        case .choice, .multiChoice, .judgment, .fillBlank:
            Subject.allCases.filter { $0 != .other }
        case .matching:
            [.english, .chinese]
        case .shortAnswer:
            [.chinese, .history, .geography, .politics, .ethics, .biology]
        case .calculation:
            [.math, .physics, .chemistry]
        case .proof:
            [.math, .physics]
        case .drawing:
            [.math, .physics, .geography]
        case .experiment:
            [.physics, .chemistry, .biology, .science]
        case .analysis:
            [.history, .geography, .politics]
        case .reading:
            [.chinese, .english]
        case .writing:
            [.chinese, .english]
        case .cloze:
            [.english]
        case .other:
            Subject.allCases
        }
    }
    
    /// 是否适用于指定学科
    ///
    /// - Parameter subject: 要检查的学科
    /// - Returns: 该题型是否常见于该学科
    nonisolated func isApplicable(to subject: Subject) -> Bool {
        applicableSubjects.contains(subject)
    }
}

// MARK: - ReviewItemType Static Collections

extension ReviewItemType {
    
    /// 所有客观题类型
    nonisolated static var objectiveTypes: [ReviewItemType] {
        [.choice, .multiChoice, .judgment, .fillBlank, .matching]
    }
    
    /// 所有主观题类型
    nonisolated static var subjectiveTypes: [ReviewItemType] {
        [.shortAnswer, .calculation, .proof, .drawing, .experiment, .analysis]
    }
    
    /// 所有综合题类型
    nonisolated static var comprehensiveTypes: [ReviewItemType] {
        [.reading, .writing, .cloze]
    }
}

// MARK: - ReviewItemType Query Methods

extension ReviewItemType {
    
    /// 获取某分类下的所有题型
    ///
    /// - Parameter category: 题型分类
    /// - Returns: 该分类下的所有题型
    nonisolated static func types(in category: ReviewItemCategory) -> [ReviewItemType] {
        allCases.filter { $0.category == category }
    }
    
    /// 获取适用于某学科的题型
    ///
    /// - Parameter subject: 学科
    /// - Returns: 适用于该学科的所有题型
    nonisolated static func types(for subject: Subject) -> [ReviewItemType] {
        allCases.filter { $0.applicableSubjects.contains(subject) }
    }
    
    /// 按预估时间排序的所有题型
    ///
    /// 从快到慢排序。
    nonisolated static var sortedByTime: [ReviewItemType] {
        allCases.sorted { $0.estimatedMinutes < $1.estimatedMinutes }
    }
    
    /// 按难度权重排序的所有题型
    ///
    /// 从简单到困难排序。
    nonisolated static var sortedByDifficulty: [ReviewItemType] {
        allCases.sorted { $0.difficultyWeight < $1.difficultyWeight }
    }
}
