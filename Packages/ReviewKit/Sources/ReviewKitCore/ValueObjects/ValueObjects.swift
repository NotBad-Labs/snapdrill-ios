import Foundation

// MARK: - Subject

/// 学科枚举
public enum Subject: String, CaseIterable, Codable, Identifiable, Sendable {
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
    
    /// 枚举标识符
    public var id: String { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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
    
    /// 对应的 SF Symbol 图标名称
    public var icon: String {
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
    public static var coreSubjects: [Subject] {
        [.math, .chinese, .english, .physics, .chemistry, .biology, .history, .geography, .politics]
    }
}

// MARK: - MasteryLevel

/// 掌握程度
///
/// 与 `ReviewScheduler` 和 `ReviewPerformance` 保持一致，范围为 0-4。
/// 这确保了领域逻辑的统一性。
///
/// | 等级 | 含义 | Scheduler 倍率 |
/// |------|------|----------------|
/// | 0 | 完全不会 | 0.5x (大幅缩短) |
/// | 1 | 模糊记忆 | 0.7x (缩短间隔) |
/// | 2 | 基本掌握 | 1.0x (标准间隔) |
/// | 3 | 熟练掌握 | 1.3x (延长间隔) |
/// | 4 | 完全掌握 | 1.6x (大幅延长) |
public enum MasteryLevel: Int, CaseIterable, Codable, Identifiable, Sendable {
    case none = 0
    case vague = 1
    case basic = 2
    case familiar = 3
    case mastered = 4
    
    /// 枚举标识符
    public var id: Int { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
        switch self {
        case .none: String(localized: "完全不会")
        case .vague: String(localized: "模糊记忆")
        case .basic: String(localized: "基本掌握")
        case .familiar: String(localized: "熟练掌握")
        case .mastered: String(localized: "完全掌握")
        }
    }
    
    /// 对应星级（0-4）
    public var stars: Int { rawValue }
    
    public init(from performance: ReviewPerformance) {
        self = MasteryLevel(rawValue: performance.rawValue) ?? .none
    }
}

// MARK: - ErrorType

/// 错因类型
public enum ErrorType: String, CaseIterable, Codable, Identifiable, Sendable {
    case concept = "concept"
    case calculation = "calculation"
    case careless = "careless"
    case method = "method"
    case memory = "memory"
    case understanding = "understanding"
    case other = "other"
    
    /// 枚举标识符
    public var id: String { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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
    
    /// 对应的 SF Symbol 图标名称
    public var icon: String {
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

/// 题型类别
public enum ReviewItemType: String, CaseIterable, Codable, Identifiable, Sendable {
    case choice = "choice"
    case multiChoice = "multi_choice"
    case fillBlank = "fill_blank"
    case shortAnswer = "short_answer"
    case calculation = "calculation"
    case proof = "proof"
    case essay = "essay"
    case other = "other"
    
    /// 枚举标识符
    public var id: String { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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
    
    /// 对应的 SF Symbol 图标名称
    public var icon: String {
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

/// 年级枚举
public enum Grade: String, CaseIterable, Codable, Identifiable, Sendable {
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
    
    /// 枚举标识符
    public var id: String { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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

/// 难度枚举
public enum Difficulty: Int, CaseIterable, Codable, Identifiable, Sendable {
    case easy = 1
    case medium = 2
    case hard = 3
    case veryHard = 4
    case extreme = 5
    
    /// 枚举标识符
    public var id: Int { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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

/// 来源类型枚举
public enum Source: String, CaseIterable, Codable, Identifiable, Sendable {
    case homework = "homework"
    case exam = "exam"
    case exercise = "exercise"
    case mock = "mock"
    case review = "review"
    case other = "other"
    
    /// 枚举标识符
    public var id: String { rawValue }
    
    /// 本地化显示名称
    public var displayName: String {
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
public struct CustomSubject: Codable, Identifiable, Sendable, Hashable {
    public let id: UUID
    /// 显示名称
    public var name: String
    /// 颜色 Hex 值
    public var colorHex: String
    /// 图标名称
    public var icon: String
    
    public init(id: UUID = UUID(), name: String, colorHex: String = "#808080", icon: String = "book") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.icon = icon
    }
}