//
//  JapanEducationSystem.swift
//  NotBad
//
//  日本教育体系（6+3+3学制）
//

import Foundation
import SwiftUI

// MARK: - JapanGrade

/// 日本年级
public enum JapanGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 小学校 (6年)
    case grade1 = "jp_grade_1"
    case grade2 = "jp_grade_2"
    case grade3 = "jp_grade_3"
    case grade4 = "jp_grade_4"
    case grade5 = "jp_grade_5"
    case grade6 = "jp_grade_6"

    // 中学校 (3年)
    case grade7 = "jp_grade_7"
    case grade8 = "jp_grade_8"
    case grade9 = "jp_grade_9"

    // 高等学校 (3年)
    case grade10 = "jp_grade_10"
    case grade11 = "jp_grade_11"
    case grade12 = "jp_grade_12"

    public var id: String { rawValue }
}

extension JapanGrade: GradeLevelProtocol {
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

    public var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .grade1: "jp_grade_1_name"
        case .grade2: "jp_grade_2_name"
        case .grade3: "jp_grade_3_name"
        case .grade4: "jp_grade_4_name"
        case .grade5: "jp_grade_5_name"
        case .grade6: "jp_grade_6_name"
        case .grade7: "jp_grade_7_name"
        case .grade8: "jp_grade_8_name"
        case .grade9: "jp_grade_9_name"
        case .grade10: "jp_grade_10_name"
        case .grade11: "jp_grade_11_name"
        case .grade12: "jp_grade_12_name"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .grade1: "jp_grade_1_short"
        case .grade2: "jp_grade_2_short"
        case .grade3: "jp_grade_3_short"
        case .grade4: "jp_grade_4_short"
        case .grade5: "jp_grade_5_short"
        case .grade6: "jp_grade_6_short"
        case .grade7: "jp_grade_7_short"
        case .grade8: "jp_grade_8_short"
        case .grade9: "jp_grade_9_short"
        case .grade10: "jp_grade_10_short"
        case .grade11: "jp_grade_11_short"
        case .grade12: "jp_grade_12_short"
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

    public var icon: String {
        switch schoolLevel {
        case .primary: "figure.child"
        case .middle: "figure.stand"
        case .high: "graduationcap"
        }
    }

    public var color: Color {
        switch schoolLevel {
        case .primary: .green
        case .middle: .orange
        case .high: .purple
        }
    }
}

// MARK: - JapanSubject

/// 日本学科
public enum JapanSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case japanese = "jp_japanese"       // 国語
    case math = "jp_math"               // 数学/算数
    case english = "jp_english"         // 英語
    case science = "jp_science"         // 理科
    case socialStudies = "jp_social"    // 社会
    case physics = "jp_physics"         // 物理
    case chemistry = "jp_chemistry"     // 化学
    case biology = "jp_biology"         // 生物
    case geography = "jp_geography"     // 地理
    case history = "jp_history"         // 歴史/日本史/世界史
    case civics = "jp_civics"           // 公民
    case other = "jp_other"

    public var id: String { rawValue }
}

extension JapanSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .japanese: "jp_subject_japanese"
        case .math: "jp_subject_math"
        case .english: "jp_subject_english"
        case .science: "jp_subject_science"
        case .socialStudies: "jp_subject_social"
        case .physics: "jp_subject_physics"
        case .chemistry: "jp_subject_chemistry"
        case .biology: "jp_subject_biology"
        case .geography: "jp_subject_geography"
        case .history: "jp_subject_history"
        case .civics: "jp_subject_civics"
        case .other: "jp_subject_other"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .japanese: "jp_subject_japanese_short"
        case .math: "jp_subject_math_short"
        case .english: "jp_subject_english_short"
        case .science: "jp_subject_science_short"
        case .socialStudies: "jp_subject_social_short"
        case .physics: "jp_subject_physics_short"
        case .chemistry: "jp_subject_chemistry_short"
        case .biology: "jp_subject_biology_short"
        case .geography: "jp_subject_geography_short"
        case .history: "jp_subject_history_short"
        case .civics: "jp_subject_civics_short"
        case .other: "jp_subject_other_short"
        }
    }

    public var category: any SubjectCategoryProtocol {
        switch self {
        case .japanese, .english:
            ChinaSubjectCategory.language
        case .math, .science, .physics, .chemistry, .biology:
            ChinaSubjectCategory.science
        case .socialStudies, .geography, .history, .civics:
            ChinaSubjectCategory.humanities
        case .other:
            ChinaSubjectCategory.other
        }
    }

    public var icon: String {
        switch self {
        case .japanese: "character.ja"
        case .math: "function"
        case .english: "a.circle"
        case .science: "flask"
        case .socialStudies: "building.columns"
        case .physics: "atom"
        case .chemistry: "flask.fill"
        case .biology: "leaf"
        case .geography: "globe.asia.australia"
        case .history: "clock.arrow.circlepath"
        case .civics: "person.3"
        case .other: "ellipsis.circle"
        }
    }

    public var color: Color {
        switch self {
        case .japanese: .red
        case .math: .blue
        case .english: .purple
        case .science: .cyan
        case .socialStudies: .orange
        case .physics: .indigo
        case .chemistry: .green
        case .biology: .mint
        case .geography: .teal
        case .history: .brown
        case .civics: .yellow
        case .other: .gray
        }
    }

    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段：国語、算数/数学、英語
        case .japanese, .math, .english:
            [.primary, .middle, .high]
        // 小学+中学
        case .science, .socialStudies:
            [.primary, .middle]
        // 中学+高校
        case .physics, .chemistry, .biology, .geography, .history, .civics:
            [.middle, .high]
        // 全学段
        case .other:
            [.primary, .middle, .high]
        }
    }
}

// MARK: - JapanEducationSystem

/// 日本教育体系
public struct JapanEducationSystem: EducationSystemProtocol {
    public typealias GradeType = JapanGrade
    public typealias SubjectType = JapanSubject

    public let region: EducationRegion = .japan
    public let name: String = "日本教育"

    public var grades: [JapanGrade] { JapanGrade.allCases }
    public var subjects: [JapanSubject] { JapanSubject.allCases }

    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "jp_school_primary",
                startGrade: 1,
                endGrade: 6,
                icon: "backpack",
                color: .green
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "jp_school_middle",
                startGrade: 7,
                endGrade: 9,
                icon: "book",
                color: .blue
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "jp_school_high",
                startGrade: 10,
                endGrade: 12,
                icon: "graduationcap",
                color: .purple
            )
        ]
    }

    public init() {}
}
