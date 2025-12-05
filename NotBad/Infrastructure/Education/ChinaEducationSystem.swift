//
//  ChinaEducationSystem.swift
//  NotBad
//
//  中国教育体系 (6-3-3学制)
//
//  小学：1-6年级（6年）
//  初中：7-9年级（3年）- 对应初一、初二、初三
//  高中：10-12年级（3年）- 对应高一、高二、高三
//

import Foundation
import SwiftUI

// MARK: - ChinaGrade

/// 中国年级 (1-12年级)
///
/// 完整覆盖中国K12教育的12个年级。
public enum ChinaGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, GradeLevelProtocol {
    // 小学
    case grade1 = "grade_1"
    case grade2 = "grade_2"
    case grade3 = "grade_3"
    case grade4 = "grade_4"
    case grade5 = "grade_5"
    case grade6 = "grade_6"
    // 初中
    case grade7 = "grade_7"  // 初一
    case grade8 = "grade_8"  // 初二
    case grade9 = "grade_9"  // 初三
    // 高中
    case grade10 = "grade_10"   // 十年级
    case grade11 = "grade_11"   // 十一年级
    case grade12 = "grade_12"   // 十二年级

    // MARK: - GradeLevelProtocol

    public var id: String { rawValue }

    public var order: Int {
        switch self {
        case .grade1: 1
        case .grade2: 2
        case .grade3: 3
        case .grade4: 4
        case .grade5: 5
        case .grade6: 6
        case .grade7: 7
        case .grade8: 8
        case .grade9: 9
        case .grade10: 10
        case .grade11: 11
        case .grade12: 12
        }
    }

    public var schoolLevel: SchoolLevel {
        switch self {
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            .primary
        case .grade7, .grade8, .grade9:
            .middle
        case .grade10, .grade11, .grade12:
            .high
        }
    }

    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .grade1: "cn_grade_1"
        case .grade2: "cn_grade_2"
        case .grade3: "cn_grade_3"
        case .grade4: "cn_grade_4"
        case .grade5: "cn_grade_5"
        case .grade6: "cn_grade_6"
        case .grade7: "cn_grade_7"
        case .grade8: "cn_grade_8"
        case .grade9: "cn_grade_9"
        case .grade10: "cn_grade_10"
        case .grade11: "cn_grade_11"
        case .grade12: "cn_grade_12"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .grade1: "cn_grade_1_short"
        case .grade2: "cn_grade_2_short"
        case .grade3: "cn_grade_3_short"
        case .grade4: "cn_grade_4_short"
        case .grade5: "cn_grade_5_short"
        case .grade6: "cn_grade_6_short"
        case .grade7: "cn_grade_7_short"
        case .grade8: "cn_grade_8_short"
        case .grade9: "cn_grade_9_short"
        case .grade10: "cn_grade_10_short"
        case .grade11: "cn_grade_11_short"
        case .grade12: "cn_grade_12_short"
        }
    }

    public var icon: String {
        switch self {
        case .grade1, .grade2:
            "figure.child"
        case .grade3, .grade4, .grade5, .grade6:
            "figure.child.and.lock"
        case .grade7, .grade8, .grade9:
            "figure.stand"
        case .grade10, .grade11, .grade12:
            "graduationcap"
        }
    }

    public var color: Color {
        switch self {
        // 小学：绿色系渐变
        case .grade1: .mint
        case .grade2: .green
        case .grade3: .teal
        case .grade4: .cyan
        case .grade5: .blue
        case .grade6: .indigo
        // 初中：暖色系
        case .grade7: .yellow
        case .grade8: .orange
        case .grade9: .red
        // 高中：紫色系
        case .grade10: .pink
        case .grade11: .purple
        case .grade12: Color(red: 0.5, green: 0, blue: 0.5)
        }
    }

    /// 是否为毕业年级
    public var isGraduationYear: Bool {
        switch self {
        case .grade6, .grade9, .grade12: true
        default: false
        }
    }

    /// 根据序号创建年级
    public static func from(order: Int) -> ChinaGrade? {
        allCases.first { $0.order == order }
    }
}

// MARK: - ChinaSubjectCategory

/// 中国学科分类
public enum ChinaSubjectCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, SubjectCategoryProtocol {
    case language = "language"
    case science = "science"
    case humanities = "humanities"
    case technology = "technology"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .language: "cn_subject_category_language"
        case .science: "cn_subject_category_science"
        case .humanities: "cn_subject_category_humanities"
        case .technology: "cn_subject_category_technology"
        case .other: "cn_subject_category_other"
        }
    }

    public var icon: String {
        switch self {
        case .language: "textformat"
        case .science: "flask"
        case .humanities: "book"
        case .technology: "desktopcomputer"
        case .other: "ellipsis.circle"
        }
    }

    public var color: Color {
        switch self {
        case .language: .red
        case .science: .blue
        case .humanities: .orange
        case .technology: .purple
        case .other: .gray
        }
    }
}

// MARK: - ChinaSubject

/// 中国学科
///
/// 覆盖中国K12教育的所有主要学科。
public enum ChinaSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 语言类
    case chinese = "chinese"
    case english = "english"

    // 理科类
    case math = "math"
    case physics = "physics"
    case chemistry = "chemistry"
    case biology = "biology"
    case science = "science"  // 小学初中科学课

    // 人文类
    case history = "history"
    case geography = "geography"
    case politics = "politics"     // 思想政治（高中）
    case ethics = "ethics" // 道法（小学初中）

    // 技术类
    case informationTech = "information_tech"
    case generalTech = "general_tech"  // 高中

    // 其他
    case other = "other"

    public var id: String { rawValue }
}

// MARK: - ChinaSubject SubjectProtocol

extension ChinaSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .chinese: "cn_subject_chinese"
        case .english: "cn_subject_english"
        case .math: "cn_subject_math"
        case .physics: "cn_subject_physics"
        case .chemistry: "cn_subject_chemistry"
        case .biology: "cn_subject_biology"
        case .science: "cn_subject_science"
        case .history: "cn_subject_history"
        case .geography: "cn_subject_geography"
        case .politics: "cn_subject_politics"
        case .ethics: "cn_subject_ethics"
        case .informationTech: "cn_subject_info_tech"
        case .generalTech: "cn_subject_general_tech"
        case .other: "cn_subject_other"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .chinese: "cn_subject_chinese_short"
        case .english: "cn_subject_english_short"
        case .math: "cn_subject_math_short"
        case .physics: "cn_subject_physics_short"
        case .chemistry: "cn_subject_chemistry_short"
        case .biology: "cn_subject_biology_short"
        case .science: "cn_subject_science_short"
        case .history: "cn_subject_history_short"
        case .geography: "cn_subject_geography_short"
        case .politics: "cn_subject_politics_short"
        case .ethics: "cn_subject_ethics_short"
        case .informationTech: "cn_subject_info_tech_short"
        case .generalTech: "cn_subject_general_tech_short"
        case .other: "cn_subject_other_short"
        }
    }

    public var category: any SubjectCategoryProtocol {
        chinaCategory
    }

    public var chinaCategory: ChinaSubjectCategory {
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

    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段：语数英
        case .chinese, .math, .english:
            [.primary, .middle, .high]
        // 小学+初中
        case .science, .ethics:
            [.primary, .middle]
        // 初中+高中
        case .physics, .chemistry, .history, .geography, .politics, .biology:
            [.middle, .high]
        // 仅高中
        case .generalTech:
            [.high]
        // 全学段
        case .informationTech, .other:
            [.primary, .middle, .high]
        }
    }

    public var icon: String {
        switch self {
        case .chinese: "character.book.closed.zh"
        case .english: "a.circle"
        case .math: "function"
        case .physics: "atom"
        case .chemistry: "flask"
        case .biology: "leaf"
        case .science: "testtube.2"
        case .history: "clock.arrow.circlepath"
        case .geography: "globe.asia.australia"
        case .politics: "building.columns"
        case .ethics: "heart.text.square"
        case .informationTech: "desktopcomputer"
        case .generalTech: "gearshape.2"
        case .other: "ellipsis.circle"
        }
    }

    public var color: Color {
        switch self {
        case .chinese: .red
        case .english: .blue
        case .math: .purple
        case .physics: .cyan
        case .chemistry: .orange
        case .biology: .green
        case .science: .teal
        case .history: .brown
        case .geography: .mint
        case .politics: .indigo
        case .ethics: .pink
        case .informationTech: .gray
        case .generalTech: .secondary
        case .other: .secondary
        }
    }
}

// MARK: - ChinaEducationSystem

/// 中国教育体系
///
/// 实现中国 6-3-3 学制的完整配置。
public struct ChinaEducationSystem: EducationSystemProtocol, Sendable {
    public typealias GradeType = ChinaGrade
    public typealias SubjectType = ChinaSubject

    public let region = EducationRegion.china

    public var name: String {
        String(localized: "cn_education_system_name")
    }

    public var grades: [ChinaGrade] {
        ChinaGrade.allCases
    }

    public var subjects: [ChinaSubject] {
        ChinaSubject.allCases
    }

    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "cn_school_level_primary",
                startGrade: 1,
                endGrade: 6,
                icon: "figure.child",
                color: .green
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "cn_school_level_middle",
                startGrade: 7,
                endGrade: 9,
                icon: "figure.stand",
                color: .orange
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "cn_school_level_high",
                startGrade: 10,
                endGrade: 12,
                icon: "graduationcap",
                color: .purple
            )
        ]
    }

    public init() {}

    // MARK: - 中国特有的学科组合

    /// 主科（语数英）
    public var coreSubjects: [ChinaSubject] {
        [.chinese, .math, .english]
    }

    /// 中考学科
    public var juniorExamSubjects: [ChinaSubject] {
        [.chinese, .math, .english, .physics, .chemistry, .history, .geography, .politics, .biology]
    }

    /// 高考学科
    public var seniorExamSubjects: [ChinaSubject] {
        [.chinese, .math, .english, .physics, .chemistry, .biology, .history, .geography, .politics]
    }

    /// 理科组合（物化生）
    public var scienceCombo: [ChinaSubject] {
        [.physics, .chemistry, .biology]
    }

    /// 文科组合（史地政）
    public var humanitiesCombo: [ChinaSubject] {
        [.history, .geography, .politics]
    }

    /// 毕业年级
    public var graduationGrades: [ChinaGrade] {
        [.grade6, .grade9, .grade12]
    }
}
