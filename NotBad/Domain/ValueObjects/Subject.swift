//
//  Subject.swift
//  NotBad
//
//  学科值对象 - K12完整覆盖
//

import SwiftUI

// MARK: - SubjectCategory

/// 学科分类
///
/// 将学科按性质分为五大类别，便于筛选和展示。
///
/// ## 分类说明
/// - ``language``: 语言类 - 语文、英语
/// - ``science``: 理科类 - 数学、物理、化学、生物、科学
/// - ``humanities``: 人文类 - 历史、地理、政治、道德与法治
/// - ``technology``: 技术类 - 信息技术、通用技术
/// - ``other``: 其他 - 无法归类的学科
///
/// ## 使用示例
/// ```swift
/// let category = SubjectCategory.science
/// print(category.displayName)  // "理科"
/// print(category.icon)         // "flask"
/// ```
enum SubjectCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case language = "language"
    case science = "science"
    case humanities = "humanities"
    case technology = "technology"
    case other = "other"
    
    // MARK: Identifiable
    
    nonisolated var id: String { rawValue }
}

// MARK: - SubjectCategory Display Properties

extension SubjectCategory {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }
    
    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .language: "subject_category_language"
        case .science: "subject_category_science"
        case .humanities: "subject_category_humanities"
        case .technology: "subject_category_technology"
        case .other: "subject_category_other"
        }
    }
    
    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .language: "textformat"
        case .science: "flask"
        case .humanities: "book"
        case .technology: "desktopcomputer"
        case .other: "ellipsis.circle"
        }
    }
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .language: .red
        case .science: .blue
        case .humanities: .orange
        case .technology: .purple
        case .other: .gray
        }
    }
}

// MARK: - Subject

/// 学科（K12全覆盖）
///
/// 覆盖小学、初中、高中所有主要学科，支持按学段筛选。
///
/// ## 学科列表
///
/// ### 语言类
/// - ``chinese``: 语文
/// - ``english``: 英语
///
/// ### 理科类
/// - ``math``: 数学
/// - ``physics``: 物理
/// - ``chemistry``: 化学
/// - ``biology``: 生物
/// - ``science``: 科学（小学、初中）
///
/// ### 人文类
/// - ``history``: 历史
/// - ``geography``: 地理
/// - ``politics``: 政治
/// - ``ethics``: 道德与法治
///
/// ### 技术类
/// - ``informationTech``: 信息技术
/// - ``generalTech``: 通用技术
///
/// ## 使用示例
/// ```swift
/// // 获取高中适用学科
/// let seniorSubjects = Subject.subjects(for: .senior)
///
/// // 检查学科是否适用于某学段
/// let isApplicable = Subject.physics.isApplicable(for: .junior)
/// ```
enum Subject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 语言类
    /// 语文
    case chinese = "chinese"
    /// 英语
    case english = "english"
    
    // 理科类
    /// 数学
    case math = "math"
    /// 物理（初中、高中）
    case physics = "physics"
    /// 化学（初中、高中）
    case chemistry = "chemistry"
    /// 生物（高中）
    case biology = "biology"
    /// 科学（小学、初中科学课）
    case science = "science"
    
    // 人文类
    /// 历史（初中、高中）
    case history = "history"
    /// 地理（初中、高中）
    case geography = "geography"
    /// 政治（初中、高中）
    case politics = "politics"
    /// 道德与法治（小学、初中）
    case ethics = "ethics"
    
    // 技术类
    /// 信息技术
    case informationTech = "information_tech"
    /// 通用技术（高中）
    case generalTech = "general_tech"
    
    // 其他
    /// 其他学科
    case other = "other"
    
    // MARK: Identifiable
    
    nonisolated var id: String { rawValue }
}

// MARK: - Subject Display Properties

extension Subject {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }
    
    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .chinese: "subject_chinese"
        case .english: "subject_english"
        case .math: "subject_math"
        case .physics: "subject_physics"
        case .chemistry: "subject_chemistry"
        case .biology: "subject_biology"
        case .science: "subject_science"
        case .history: "subject_history"
        case .geography: "subject_geography"
        case .politics: "subject_politics"
        case .ethics: "subject_ethics"
        case .informationTech: "subject_information_tech"
        case .generalTech: "subject_general_tech"
        case .other: "subject_other"
        }
    }
    
    /// 简短标签（单字）
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }
    
    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .chinese: "subject_chinese_short"
        case .english: "subject_english_short"
        case .math: "subject_math_short"
        case .physics: "subject_physics_short"
        case .chemistry: "subject_chemistry_short"
        case .biology: "subject_biology_short"
        case .science: "subject_science_short"
        case .history: "subject_history_short"
        case .geography: "subject_geography_short"
        case .politics: "subject_politics_short"
        case .ethics: "subject_ethics_short"
        case .informationTech: "subject_information_tech_short"
        case .generalTech: "subject_general_tech_short"
        case .other: "subject_other_short"
        }
    }
    
    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .chinese: "character.book.closed"
        case .english: "abc"
        case .math: "function"
        case .physics: "atom"
        case .chemistry: "testtube.2"
        case .biology: "leaf"
        case .science: "sparkles"
        case .history: "clock.arrow.circlepath"
        case .geography: "globe.asia.australia"
        case .politics: "building.columns"
        case .ethics: "heart.text.square"
        case .informationTech: "desktopcomputer"
        case .generalTech: "wrench.and.screwdriver"
        case .other: "ellipsis.circle"
        }
    }
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .chinese: .red
        case .english: .purple
        case .math: .blue
        case .physics: .orange
        case .chemistry: .green
        case .biology: .mint
        case .science: .cyan
        case .history: .brown
        case .geography: .teal
        case .politics: .indigo
        case .ethics: .pink
        case .informationTech: .purple
        case .generalTech: .gray
        case .other: .secondary
        }
    }
}

// MARK: - Subject Classification

extension Subject {
    /// 学科分类
    nonisolated var category: SubjectCategory {
        switch self {
        case .chinese, .english:
            .language
        case .math, .physics, .chemistry, .biology, .science:
            .science
        case .history, .geography, .politics, .ethics:
            .humanities
        case .informationTech, .generalTech:
            .technology
        case .other:
            .other
        }
    }
    
    /// 适用学段
    nonisolated var applicableStages: [GradeStage] {
        switch self {
        // 全学段
        case .chinese, .math, .english:
            [.primary, .junior, .senior]
        // 小学+初中
        case .science, .ethics:
            [.primary, .junior]
        // 初中+高中
        case .physics, .chemistry, .history, .geography, .politics:
            [.junior, .senior]
        // 初中+高中
        case .biology:
            [.junior, .senior]
        // 仅高中
        case .generalTech:
            [.senior]
        // 全学段（信息技术）
        case .informationTech, .other:
            [.primary, .junior, .senior]
        }
    }
    
    /// 是否适用于指定学段
    /// - Parameter stage: 学段
    /// - Returns: 是否适用
    nonisolated func isApplicable(for stage: GradeStage) -> Bool {
        applicableStages.contains(stage)
    }
}

// MARK: - Subject Query Methods

extension Subject {
    /// 获取指定学段的学科列表
    /// - Parameter stage: 学段
    /// - Returns: 适用的学科数组
    static func subjects(for stage: GradeStage) -> [Subject] {
        allCases.filter { $0.isApplicable(for: stage) }
    }
    
    /// 获取指定分类的学科列表
    /// - Parameter category: 学科分类
    /// - Returns: 该分类下的学科数组
    static func subjects(in category: SubjectCategory) -> [Subject] {
        allCases.filter { $0.category == category }
    }
}

// MARK: - Subject CustomStringConvertible

extension Subject: CustomStringConvertible {
    nonisolated var description: String { displayName }
}

// MARK: - Subject Collections

extension Subject {
    /// 主要学科（语数英）
    static let coreSubjects: [Subject] = [.chinese, .math, .english]
    
    /// 中考学科
    static let juniorExamSubjects: [Subject] = [
        .chinese, .math, .english,
        .physics, .chemistry,
        .history, .geography, .politics, .biology
    ]
    
    /// 高考学科
    static let seniorExamSubjects: [Subject] = [
        .chinese, .math, .english,
        .physics, .chemistry, .biology,
        .history, .geography, .politics
    ]
    
    /// 理科组合（物化生）
    static let scienceCombo: [Subject] = [.physics, .chemistry, .biology]
    
    /// 文科组合（史地政）
    static let artsCombo: [Subject] = [.history, .geography, .politics]
}
