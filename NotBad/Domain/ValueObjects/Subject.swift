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

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .language: "subject_category_language_short"
        case .science: "subject_category_science_short"
        case .humanities: "subject_category_humanities_short"
        case .technology: "subject_category_technology_short"
        case .other: "subject_category_other_short"
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
    
    /// 根据年级获取标题占位符
    /// - Parameter grade: 年级
    /// - Returns: 标题占位符示例
    nonisolated func titlePlaceholder(for grade: Grade) -> String {
        let key = titlePlaceholderKey(for: grade.stage)
        return String(localized: key)
    }
    
    /// 标题占位符本地化键值（根据学段）
    private func titlePlaceholderKey(for stage: GradeStage) -> String.LocalizationValue {
        switch (self, stage) {
        // 语文
        case (.chinese, .primary): return "subject_placeholder_title_chinese_primary"
        case (.chinese, .junior): return "subject_placeholder_title_chinese_junior"
        case (.chinese, .senior): return "subject_placeholder_title_chinese_senior"
        // 英语
        case (.english, .primary): return "subject_placeholder_title_english_primary"
        case (.english, .junior): return "subject_placeholder_title_english_junior"
        case (.english, .senior): return "subject_placeholder_title_english_senior"
        // 数学
        case (.math, .primary): return "subject_placeholder_title_math_primary"
        case (.math, .junior): return "subject_placeholder_title_math_junior"
        case (.math, .senior): return "subject_placeholder_title_math_senior"
        // 物理（初中+高中）
        case (.physics, .primary): return "subject_placeholder_title_physics_junior"
        case (.physics, .junior): return "subject_placeholder_title_physics_junior"
        case (.physics, .senior): return "subject_placeholder_title_physics_senior"
        // 化学（初中+高中）
        case (.chemistry, .primary): return "subject_placeholder_title_chemistry_junior"
        case (.chemistry, .junior): return "subject_placeholder_title_chemistry_junior"
        case (.chemistry, .senior): return "subject_placeholder_title_chemistry_senior"
        // 生物（初中+高中）
        case (.biology, .primary): return "subject_placeholder_title_biology_junior"
        case (.biology, .junior): return "subject_placeholder_title_biology_junior"
        case (.biology, .senior): return "subject_placeholder_title_biology_senior"
        // 科学（小学+初中）
        case (.science, .primary): return "subject_placeholder_title_science_primary"
        case (.science, .junior): return "subject_placeholder_title_science_junior"
        case (.science, .senior): return "subject_placeholder_title_science_junior"
        // 历史（初中+高中）
        case (.history, .primary): return "subject_placeholder_title_history_junior"
        case (.history, .junior): return "subject_placeholder_title_history_junior"
        case (.history, .senior): return "subject_placeholder_title_history_senior"
        // 地理（初中+高中）
        case (.geography, .primary): return "subject_placeholder_title_geography_junior"
        case (.geography, .junior): return "subject_placeholder_title_geography_junior"
        case (.geography, .senior): return "subject_placeholder_title_geography_senior"
        // 政治（初中+高中）
        case (.politics, .primary): return "subject_placeholder_title_politics_junior"
        case (.politics, .junior): return "subject_placeholder_title_politics_junior"
        case (.politics, .senior): return "subject_placeholder_title_politics_senior"
        // 道德与法治（小学+初中）
        case (.ethics, .primary): return "subject_placeholder_title_ethics_primary"
        case (.ethics, .junior): return "subject_placeholder_title_ethics_junior"
        case (.ethics, .senior): return "subject_placeholder_title_ethics_junior"
        // 信息技术
        case (.informationTech, .primary): return "subject_placeholder_title_it_primary"
        case (.informationTech, .junior): return "subject_placeholder_title_it_junior"
        case (.informationTech, .senior): return "subject_placeholder_title_it_senior"
        // 通用技术（高中）
        case (.generalTech, _): return "subject_placeholder_title_tech"
        // 其他
        case (.other, _): return "subject_placeholder_title_other"
        }
    }
    
    /// 根据年级获取知识点占位符
    /// - Parameter grade: 年级
    /// - Returns: 知识点占位符示例
    nonisolated func knowledgePointsPlaceholder(for grade: Grade) -> String {
        let key = knowledgePointsPlaceholderKey(for: grade.stage)
        return String(localized: key)
    }
    
    /// 知识点占位符本地化键值（根据学段）
    private func knowledgePointsPlaceholderKey(for stage: GradeStage) -> String.LocalizationValue {
        switch (self, stage) {
        // 语文
        case (.chinese, .primary): return "subject_placeholder_kp_chinese_primary"
        case (.chinese, .junior): return "subject_placeholder_kp_chinese_junior"
        case (.chinese, .senior): return "subject_placeholder_kp_chinese_senior"
        // 英语
        case (.english, .primary): return "subject_placeholder_kp_english_primary"
        case (.english, .junior): return "subject_placeholder_kp_english_junior"
        case (.english, .senior): return "subject_placeholder_kp_english_senior"
        // 数学
        case (.math, .primary): return "subject_placeholder_kp_math_primary"
        case (.math, .junior): return "subject_placeholder_kp_math_junior"
        case (.math, .senior): return "subject_placeholder_kp_math_senior"
        // 物理
        case (.physics, .primary): return "subject_placeholder_kp_physics_junior"
        case (.physics, .junior): return "subject_placeholder_kp_physics_junior"
        case (.physics, .senior): return "subject_placeholder_kp_physics_senior"
        // 化学
        case (.chemistry, .primary): return "subject_placeholder_kp_chemistry_junior"
        case (.chemistry, .junior): return "subject_placeholder_kp_chemistry_junior"
        case (.chemistry, .senior): return "subject_placeholder_kp_chemistry_senior"
        // 生物
        case (.biology, .primary): return "subject_placeholder_kp_biology_junior"
        case (.biology, .junior): return "subject_placeholder_kp_biology_junior"
        case (.biology, .senior): return "subject_placeholder_kp_biology_senior"
        // 科学
        case (.science, .primary): return "subject_placeholder_kp_science_primary"
        case (.science, .junior): return "subject_placeholder_kp_science_junior"
        case (.science, .senior): return "subject_placeholder_kp_science_junior"
        // 历史
        case (.history, .primary): return "subject_placeholder_kp_history_junior"
        case (.history, .junior): return "subject_placeholder_kp_history_junior"
        case (.history, .senior): return "subject_placeholder_kp_history_senior"
        // 地理
        case (.geography, .primary): return "subject_placeholder_kp_geography_junior"
        case (.geography, .junior): return "subject_placeholder_kp_geography_junior"
        case (.geography, .senior): return "subject_placeholder_kp_geography_senior"
        // 政治
        case (.politics, .primary): return "subject_placeholder_kp_politics_junior"
        case (.politics, .junior): return "subject_placeholder_kp_politics_junior"
        case (.politics, .senior): return "subject_placeholder_kp_politics_senior"
        // 道德与法治
        case (.ethics, .primary): return "subject_placeholder_kp_ethics_primary"
        case (.ethics, .junior): return "subject_placeholder_kp_ethics_junior"
        case (.ethics, .senior): return "subject_placeholder_kp_ethics_junior"
        // 信息技术
        case (.informationTech, .primary): return "subject_placeholder_kp_it_primary"
        case (.informationTech, .junior): return "subject_placeholder_kp_it_junior"
        case (.informationTech, .senior): return "subject_placeholder_kp_it_senior"
        // 通用技术
        case (.generalTech, _): return "subject_placeholder_kp_tech"
        // 其他
        case (.other, _): return "subject_placeholder_kp_other"
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

    /// 适用学段（中国大陆学制）
    /// 
    /// 此属性返回中国大陆教育体系下的学科适用学段。
    /// 如需获取其他地区的适用学段，请使用 `applicableStages(for:)` 方法。
    nonisolated var applicableStages: [GradeStage] {
        applicableStages(for: .china)
    }
    
    /// 获取指定教育地区的适用学段
    /// - Parameter region: 教育地区
    /// - Returns: 适用的学段数组
    nonisolated func applicableStages(for region: EducationRegion) -> [GradeStage] {
        switch region {
        case .china:
            // 中国大陆学制
            switch self {
            case .chinese, .math, .english:
                [.primary, .junior, .senior]
            case .science, .ethics:
                [.primary, .junior]
            case .physics, .chemistry, .history, .geography, .politics, .biology:
                [.junior, .senior]
            case .generalTech:
                [.senior]
            case .informationTech, .other:
                [.primary, .junior, .senior]
            }
        case .japan:
            // 日本学制：理科(科学)贯穿全学段，社会科目从小学开始
            switch self {
            case .chinese, .math, .english:
                [.primary, .junior, .senior]
            case .science:  // 日本的理科从小学就有
                [.primary, .junior, .senior]
            case .physics, .chemistry, .biology:
                [.junior, .senior]
            case .history, .geography, .politics:  // 社会科从小学开始
                [.primary, .junior, .senior]
            case .ethics:  // 道德教育贯穿
                [.primary, .junior, .senior]
            case .informationTech:
                [.junior, .senior]
            case .generalTech, .other:
                [.primary, .junior, .senior]
            }
        case .korea:
            // 韩国学制：6-3-3结构，与中国类似但有细微差别
            switch self {
            case .chinese, .math, .english:
                [.primary, .junior, .senior]
            case .science:  // 韩国小学有"科学"课
                [.primary, .junior]
            case .physics, .chemistry, .biology:
                [.junior, .senior]
            case .history, .geography, .politics:  // 社会科从小学开始（사회）
                [.primary, .junior, .senior]
            case .ethics:  // 道德从小学开始（도덕）
                [.primary, .junior]
            case .informationTech:  // 信息从小学高年级开始
                [.primary, .junior, .senior]
            case .generalTech:
                [.senior]
            case .other:
                [.primary, .junior, .senior]
            }
        case .singapore:
            // 新加坡学制：6-4-2结构（小学6年+中学4年+初级学院2年）
            switch self {
            case .chinese, .math, .english:  // 双语教育，从小学开始
                [.primary, .junior, .senior]
            case .science:  // Primary Science 从小学开始
                [.primary, .junior, .senior]
            case .physics, .chemistry, .biology:  // 中学分科
                [.junior, .senior]
            case .history, .geography:  // Social Studies/Humanities
                [.primary, .junior, .senior]
            case .politics:  // Social Studies 的一部分
                [.junior, .senior]
            case .ethics:  // Character and Citizenship Education
                [.primary, .junior, .senior]
            case .informationTech:  // Computing 从中学开始
                [.junior, .senior]
            case .generalTech:  // Design & Technology
                [.junior, .senior]
            case .other:
                [.primary, .junior, .senior]
            }
        case .usa:
            // 美国学制：K-5 + 6-8 + 9-12（因州而异）
            switch self {
            case .chinese:  // 通常作为外语，从中学开始
                [.junior, .senior]
            case .math, .english:  // 核心课程，全学段
                [.primary, .junior, .senior]
            case .science:  // Science 贯穿 K-12
                [.primary, .junior, .senior]
            case .physics, .chemistry, .biology:  // 高中分科
                [.senior]
            case .history, .geography, .politics:  // Social Studies 从小学开始
                [.primary, .junior, .senior]
            case .ethics:  // 不单独设课，融入其他课程
                [.junior, .senior]
            case .informationTech:  // Computer Science
                [.primary, .junior, .senior]
            case .generalTech:  // Technology Education
                [.junior, .senior]
            case .other:
                [.primary, .junior, .senior]
            }
        case .uk:
            // 英国学制：Primary 1-6 + Secondary 7-11 + Sixth Form 12-13
            switch self {
            case .chinese:  // 作为 MFL（现代外语），从中学开始
                [.junior, .senior]
            case .math, .english:  // 核心课程，全学段必修
                [.primary, .junior, .senior]
            case .science:  // Science 必修到 GCSE
                [.primary, .junior, .senior]
            case .physics, .chemistry, .biology:  // A-Level 分科（Sixth Form）
                [.senior]
            case .history, .geography:  // 从小学开始（Key Stage 1）
                [.primary, .junior, .senior]
            case .politics:  // Citizenship/Politics A-Level
                [.junior, .senior]
            case .ethics:  // PSHE/Religious Education
                [.primary, .junior, .senior]
            case .informationTech:  // Computing
                [.primary, .junior, .senior]
            case .generalTech:  // Design and Technology
                [.primary, .junior, .senior]
            case .other:
                [.primary, .junior, .senior]
            }
        case .international, .custom:
            // 国际学校/IB体系/自定义：灵活配置，大多数学科全学段可选
            switch self {
            case .chinese, .math, .english:
                [.primary, .junior, .senior]
            case .science:
                [.primary, .junior, .senior]
            case .physics, .chemistry, .biology:
                [.junior, .senior]
            case .history, .geography, .politics:
                [.primary, .junior, .senior]
            case .ethics:
                [.primary, .junior, .senior]
            case .informationTech:
                [.primary, .junior, .senior]
            case .generalTech:
                [.junior, .senior]
            case .other:
                [.primary, .junior, .senior]
            }
        }
    }

    /// 是否适用于指定学段
    /// - Parameter stage: 学段
    /// - Returns: 是否适用
    nonisolated func isApplicable(for stage: GradeStage) -> Bool {
        applicableStages.contains(stage)
    }
    
    /// 是否适用于指定学段（指定教育地区）
    /// - Parameters:
    ///   - stage: 学段
    ///   - region: 教育地区
    /// - Returns: 是否适用
    nonisolated func isApplicable(for stage: GradeStage, in region: EducationRegion) -> Bool {
        applicableStages(for: region).contains(stage)
    }
    
    /// 是否适用于指定年级
    /// - Parameter grade: 年级
    /// - Returns: 是否适用
    nonisolated func isApplicable(for grade: Grade) -> Bool {
        applicableStages.contains(grade.stage)
    }
    
    /// 是否适用于指定年级（指定教育地区）
    /// - Parameters:
    ///   - grade: 年级
    ///   - region: 教育地区
    /// - Returns: 是否适用
    nonisolated func isApplicable(for grade: Grade, in region: EducationRegion) -> Bool {
        applicableStages(for: region).contains(grade.stage)
    }
    
    /// 获取该学科适用的所有年级（使用默认地区：中国大陆）
    /// - Returns: 适用的年级数组（不含幼儿园）
    nonisolated var applicableGrades: [Grade] {
        applicableGrades(for: .china)
    }
    
    /// 获取该学科在指定教育地区适用的所有年级
    /// - Parameter region: 教育地区
    /// - Returns: 适用的年级数组（不含幼儿园）
    nonisolated func applicableGrades(for region: EducationRegion) -> [Grade] {
        let stages = applicableStages(for: region)
        return Grade.allCases.filter { grade in
            grade != .kindergarten && stages.contains(grade.stage)
        }
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
