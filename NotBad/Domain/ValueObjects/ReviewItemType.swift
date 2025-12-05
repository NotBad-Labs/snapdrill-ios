//
//  ReviewItemType.swift
//  NotBad
//
//  题型值对象
//

import Foundation

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
    case choice = "choice"

    /// 多选题
    ///
    /// 多项选择，通常有多个正确答案。
    case multiChoice = "multiChoice"

    /// 判断题
    ///
    /// 判断对错，二选一。
    case judgment = "judgment"

    /// 填空题
    ///
    /// 填写空缺内容，答案通常唯一。
    case fillBlank = "fillBlank"

    /// 连线题
    ///
    /// 将相关内容进行匹配连接。
    case matching = "matching"

    // MARK: - Subjective Types (主观题)

    /// 简答题
    ///
    /// 简要回答问题，通常有要点采分。
    case shortAnswer = "shortAnswer"

    /// 计算题
    ///
    /// 需要列式计算，按步骤给分。
    case calculation = "calculation"

    /// 证明题
    ///
    /// 数学或物理证明，逻辑严密性要求高。
    case proof = "proof"

    /// 作图题
    ///
    /// 绘制图形、图表或示意图。
    case drawing = "drawing"

    /// 实验题
    ///
    /// 涉及实验设计、现象描述、结论分析。
    case experiment = "experiment"

    /// 材料分析
    ///
    /// 根据给定材料进行分析回答。
    case analysis = "analysis"

    // MARK: - Comprehensive Types (综合题)

    /// 阅读理解
    ///
    /// 语文或英语阅读，综合理解能力。
    case reading = "reading"

    /// 作文
    ///
    /// 写作题，考察语言表达和组织能力。
    case writing = "writing"

    /// 完形填空
    ///
    /// 英语完形填空，综合语法和语境理解。
    case cloze = "cloze"

    // MARK: - Other

    /// 其他
    ///
    /// 不便分类的特殊题型。
    case other = "other"

    // MARK: - Identifiable

    /// 唯一标识符
    nonisolated var id: String { rawValue }
}

// MARK: - ReviewItemType Display Properties

extension ReviewItemType {

    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .choice: "item_type_choice"
        case .multiChoice: "item_type_multi_choice"
        case .judgment: "item_type_judgment"
        case .fillBlank: "item_type_fill_blank"
        case .matching: "item_type_matching"
        case .shortAnswer: "item_type_short_answer"
        case .calculation: "item_type_calculation"
        case .proof: "item_type_proof"
        case .drawing: "item_type_drawing"
        case .experiment: "item_type_experiment"
        case .analysis: "item_type_analysis"
        case .reading: "item_type_reading"
        case .writing: "item_type_writing"
        case .cloze: "item_type_cloze"
        case .other: "item_type_other"
        }
    }

    /// 简短标签（单字）
    ///
    /// 用于空间有限的 UI 展示。
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .choice: "item_type_choice_short"
        case .multiChoice: "item_type_multi_choice_short"
        case .judgment: "item_type_judgment_short"
        case .fillBlank: "item_type_fill_blank_short"
        case .matching: "item_type_matching_short"
        case .shortAnswer: "item_type_short_answer_short"
        case .calculation: "item_type_calculation_short"
        case .proof: "item_type_proof_short"
        case .drawing: "item_type_drawing_short"
        case .experiment: "item_type_experiment_short"
        case .analysis: "item_type_analysis_short"
        case .reading: "item_type_reading_short"
        case .writing: "item_type_writing_short"
        case .cloze: "item_type_cloze_short"
        case .other: "item_type_other_short"
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
