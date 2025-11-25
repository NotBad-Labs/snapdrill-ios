//
//  ReviewItemType.swift
//  NotBad
//
//  错题类型值对象 - K12完整覆盖
//

import SwiftUI

/// 题型分类
enum ReviewItemCategory: String, CaseIterable, Codable {
    case objective = "客观题"   // 选择、多选、判断、填空
    case subjective = "主观题"  // 简答、计算、证明、作图、实验、材料分析
    case comprehensive = "综合题" // 阅读理解、作文
    case other = "其他"
    
    var displayName: String { rawValue }
    
    /// 图标
    var icon: String {
        switch self {
        case .objective: return "checkmark.square"
        case .subjective: return "pencil"
        case .comprehensive: return "doc.text"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .objective: return .blue
        case .subjective: return .orange
        case .comprehensive: return .purple
        case .other: return .gray
        }
    }
    
    /// 评分特点
    var gradingCharacteristic: String {
        switch self {
        case .objective: return "答案唯一，对错分明"
        case .subjective: return "答案开放，按步给分"
        case .comprehensive: return "综合能力，整体评分"
        case .other: return "视具体情况而定"
        }
    }
}

/// 错题类型（题型）
enum ReviewItemType: String, CaseIterable, Codable {
    // 客观题
    case choice = "选择题"
    case multiChoice = "多选题"
    case judgment = "判断题"
    case fillBlank = "填空题"
    case matching = "连线题"
    
    // 主观题
    case shortAnswer = "简答题"
    case calculation = "计算题"
    case proof = "证明题"
    case drawing = "作图题"
    case experiment = "实验题"
    case analysis = "材料分析"
    
    // 综合题
    case reading = "阅读理解"
    case writing = "作文"
    case cloze = "完形填空"
    
    // 其他
    case other = "其他"
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .choice: return "选"
        case .multiChoice: return "多"
        case .judgment: return "判"
        case .fillBlank: return "填"
        case .matching: return "连"
        case .shortAnswer: return "简"
        case .calculation: return "算"
        case .proof: return "证"
        case .drawing: return "图"
        case .experiment: return "实"
        case .analysis: return "析"
        case .reading: return "读"
        case .writing: return "写"
        case .cloze: return "完"
        case .other: return "他"
        }
    }
    
    /// 题型分类
    var category: ReviewItemCategory {
        switch self {
        case .choice, .multiChoice, .judgment, .fillBlank, .matching:
            return .objective
        case .shortAnswer, .calculation, .proof, .drawing, .experiment, .analysis:
            return .subjective
        case .reading, .writing, .cloze:
            return .comprehensive
        case .other:
            return .other
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .choice: return "checkmark.circle"
        case .multiChoice: return "checklist"
        case .judgment: return "hand.thumbsup"
        case .fillBlank: return "square.and.pencil"
        case .matching: return "arrow.left.arrow.right"
        case .shortAnswer: return "text.alignleft"
        case .calculation: return "function"
        case .proof: return "arrow.right.arrow.left"
        case .drawing: return "pencil.and.ruler"
        case .experiment: return "flask"
        case .analysis: return "doc.text.magnifyingglass"
        case .reading: return "book"
        case .writing: return "pencil.line"
        case .cloze: return "text.badge.minus"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .choice: return .blue
        case .multiChoice: return .indigo
        case .judgment: return .cyan
        case .fillBlank: return .green
        case .matching: return .teal
        case .shortAnswer: return .orange
        case .calculation: return .red
        case .proof: return .purple
        case .drawing: return .pink
        case .experiment: return .mint
        case .analysis: return .brown
        case .reading: return .yellow
        case .writing: return .red
        case .cloze: return .indigo
        case .other: return .gray
        }
    }
    
    /// 预估答题时间（分钟）
    var estimatedMinutes: Int {
        switch self {
        case .choice, .judgment: return 1
        case .multiChoice, .fillBlank, .matching: return 2
        case .shortAnswer, .drawing: return 5
        case .calculation, .experiment: return 8
        case .proof, .analysis: return 10
        case .reading, .cloze: return 15
        case .writing: return 30
        case .other: return 5
        }
    }
    
    /// 常见适用学科
    var applicableSubjects: [Subject] {
        switch self {
        case .choice, .multiChoice, .judgment, .fillBlank:
            return Subject.allCases.filter { $0 != .other }
        case .matching:
            return [.english, .chinese]
        case .shortAnswer:
            return [.chinese, .history, .geography, .politics, .ethics, .biology]
        case .calculation:
            return [.math, .physics, .chemistry]
        case .proof:
            return [.math, .physics]
        case .drawing:
            return [.math, .physics, .geography]
        case .experiment:
            return [.physics, .chemistry, .biology, .science]
        case .analysis:
            return [.history, .geography, .politics]
        case .reading:
            return [.chinese, .english]
        case .writing:
            return [.chinese, .english]
        case .cloze:
            return [.english]
        case .other:
            return Subject.allCases
        }
    }
    
    /// 是否为客观题（有唯一答案）
    var isObjective: Bool {
        category == .objective
    }
    
    /// 难度权重（综合题和主观题通常更难）
    var difficultyWeight: Double {
        switch category {
        case .objective: return 1.0
        case .subjective: return 1.5
        case .comprehensive: return 2.0
        case .other: return 1.0
        }
    }
}

// MARK: - 统计辅助

extension ReviewItemType {
    /// 获取某分类下的所有题型
    static func types(in category: ReviewItemCategory) -> [ReviewItemType] {
        allCases.filter { $0.category == category }
    }
    
    /// 获取适用于某学科的题型
    static func types(for subject: Subject) -> [ReviewItemType] {
        allCases.filter { $0.applicableSubjects.contains(subject) }
    }
}
