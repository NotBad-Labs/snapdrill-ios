//
//  ValueObjects.swift
//  NotBad
//
//  ⚠️ 已迁移到 ReviewKit Package
//
//  这个文件已迁移到 Packages/ReviewKit/Sources/ReviewKit/ValueObjects/
//  待 Xcode 添加 ReviewKit 依赖后删除此文件。
//
//  迁移步骤：
//  1. 在 Xcode 中，选择 NotBad project
//  2. 点击 "Package Dependencies"
//  3. 添加本地 Package: Packages/ReviewKit
//  4. 在 NotBad target 的 "Frameworks, Libraries..." 中添加 ReviewKit
//  5. 删除此文件和 NotBad/Models/ReviewItemModel.swift
//  6. 在需要的地方添加 `import ReviewKit`
//

import Foundation

// MARK: - Subject

/// 学科枚举
enum Subject: String, CaseIterable, Codable, Identifiable, Sendable {
    case math = "math"
    case chinese = "chinese"
    case english = "english"
    case physics = "physics"
    case chemistry = "chemistry"
    case biology = "biology"
    case history = "history"
    case geography = "geography"
    case politics = "politics"
    case ethics = "ethics"
    case science = "science"
    case informationTech = "information_tech"
    case generalTech = "general_tech"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .math: String(localized: "数学")
        case .chinese: String(localized: "语文")
        case .english: String(localized: "英语")
        case .physics: String(localized: "物理")
        case .chemistry: String(localized: "化学")
        case .biology: String(localized: "生物")
        case .history: String(localized: "历史")
        case .geography: String(localized: "地理")
        case .politics: String(localized: "政治")
        case .ethics: String(localized: "道德与法治")
        case .science: String(localized: "科学")
        case .informationTech: String(localized: "信息技术")
        case .generalTech: String(localized: "通用技术")
        case .other: String(localized: "其他")
        }
    }
    
    var icon: String {
        switch self {
        case .math: "function"
        case .chinese: "text.book.closed"
        case .english: "abc"
        case .physics: "atom"
        case .chemistry: "flask"
        case .biology: "leaf"
        case .history: "clock"
        case .geography: "globe.asia.australia"
        case .politics: "building.columns"
        case .ethics: "hand.raised"
        case .science: "flask"
        case .informationTech: "desktopcomputer"
        case .generalTech: "wrench.and.screwdriver"
        case .other: "doc.questionmark"
        }
    }
    
    /// 核心学科（主要学科）
    static var coreSubjects: [Subject] {
        [.math, .chinese, .english, .physics, .chemistry, .biology, .history, .geography, .politics]
    }
}

// MARK: - MasteryLevel

/// 掌握程度
enum MasteryLevel: Int, CaseIterable, Codable, Identifiable, Sendable {
    case none = 0
    case glimpse = 1
    case partial = 2
    case good = 3
    case mastered = 4
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .none: String(localized: "未掌握")
        case .glimpse: String(localized: "初步了解")
        case .partial: String(localized: "部分掌握")
        case .good: String(localized: "基本掌握")
        case .mastered: String(localized: "完全掌握")
        }
    }
    
    var stars: Int { rawValue }
}

// MARK: - ErrorType

/// 错误类型
enum ErrorType: String, CaseIterable, Codable, Identifiable, Sendable {
    case concept = "concept"
    case calculation = "calculation"
    case careless = "careless"
    case method = "method"
    case memory = "memory"
    case understanding = "understanding"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .concept: String(localized: "概念错误")
        case .calculation: String(localized: "计算错误")
        case .careless: String(localized: "粗心大意")
        case .method: String(localized: "方法错误")
        case .memory: String(localized: "记忆错误")
        case .understanding: String(localized: "理解错误")
        case .other: String(localized: "其他")
        }
    }
    
    var icon: String {
        switch self {
        case .concept: "lightbulb.slash"
        case .calculation: "number.square"
        case .careless: "exclamationmark.triangle"
        case .method: "arrow.triangle.swap"
        case .memory: "brain.head.profile"
        case .understanding: "questionmark.circle"
        case .other: "ellipsis.circle"
        }
    }
}

// MARK: - ReviewItemType

/// 题型
enum ReviewItemType: String, CaseIterable, Codable, Identifiable, Sendable {
    case choice = "choice"
    case multiChoice = "multi_choice"
    case fillBlank = "fill_blank"
    case shortAnswer = "short_answer"
    case calculation = "calculation"
    case proof = "proof"
    case essay = "essay"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .choice: String(localized: "单选题")
        case .multiChoice: String(localized: "多选题")
        case .fillBlank: String(localized: "填空题")
        case .shortAnswer: String(localized: "简答题")
        case .calculation: String(localized: "计算题")
        case .proof: String(localized: "证明题")
        case .essay: String(localized: "作文")
        case .other: String(localized: "其他")
        }
    }
    
    var icon: String {
        switch self {
        case .choice: "checkmark.circle"
        case .multiChoice: "checkmark.square"
        case .fillBlank: "square.and.pencil"
        case .shortAnswer: "text.alignleft"
        case .calculation: "function"
        case .proof: "arrow.right"
        case .essay: "doc.text"
        case .other: "ellipsis"
        }
    }
}

// MARK: - Grade

/// 年级
enum Grade: String, CaseIterable, Codable, Identifiable, Sendable {
    case grade1 = "grade_1"
    case grade2 = "grade_2"
    case grade3 = "grade_3"
    case grade4 = "grade_4"
    case grade5 = "grade_5"
    case grade6 = "grade_6"
    case grade7 = "grade_7"
    case grade8 = "grade_8"
    case grade9 = "grade_9"
    case grade10 = "grade_10"
    case grade11 = "grade_11"
    case grade12 = "grade_12"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .grade1: String(localized: "一年级")
        case .grade2: String(localized: "二年级")
        case .grade3: String(localized: "三年级")
        case .grade4: String(localized: "四年级")
        case .grade5: String(localized: "五年级")
        case .grade6: String(localized: "六年级")
        case .grade7: String(localized: "初一")
        case .grade8: String(localized: "初二")
        case .grade9: String(localized: "初三")
        case .grade10: String(localized: "高一")
        case .grade11: String(localized: "高二")
        case .grade12: String(localized: "高三")
        }
    }
}

// MARK: - Difficulty

/// 难度等级
enum Difficulty: Int, CaseIterable, Codable, Identifiable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3
    case veryHard = 4
    case extreme = 5
    
    var id: Int { rawValue }
    
    var displayName: String {
        switch self {
        case .easy: String(localized: "简单")
        case .medium: String(localized: "中等")
        case .hard: String(localized: "较难")
        case .veryHard: String(localized: "困难")
        case .extreme: String(localized: "极难")
        }
    }
}

// MARK: - Source

/// 题目来源
enum Source: String, CaseIterable, Codable, Identifiable, Sendable {
    case homework = "homework"
    case exam = "exam"
    case exercise = "exercise"
    case mock = "mock"
    case review = "review"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .homework: String(localized: "课后作业")
        case .exam: String(localized: "考试")
        case .exercise: String(localized: "练习册")
        case .mock: String(localized: "模拟卷")
        case .review: String(localized: "复习资料")
        case .other: String(localized: "其他")
        }
    }
}

// MARK: - CustomSubject

/// 自定义学科
struct CustomSubject: Codable, Identifiable, Sendable, Hashable {
    let id: UUID
    var name: String
    var colorHex: String
    var icon: String
    
    init(id: UUID = UUID(), name: String, colorHex: String = "#808080", icon: String = "book") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }
}
