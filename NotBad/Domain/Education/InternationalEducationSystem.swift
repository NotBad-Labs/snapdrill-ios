//
//  InternationalEducationSystem.swift
//  NotBad
//
//  国际通用教育体系（Grade 1-12）
//

import Foundation
import SwiftUI

// MARK: - InternationalGrade

/// 国际通用年级
public enum InternationalGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case grade1 = "intl_grade_1"
    case grade2 = "intl_grade_2"
    case grade3 = "intl_grade_3"
    case grade4 = "intl_grade_4"
    case grade5 = "intl_grade_5"
    case grade6 = "intl_grade_6"
    case grade7 = "intl_grade_7"
    case grade8 = "intl_grade_8"
    case grade9 = "intl_grade_9"
    case grade10 = "intl_grade_10"
    case grade11 = "intl_grade_11"
    case grade12 = "intl_grade_12"

    public var id: String { rawValue }
}

extension InternationalGrade: GradeLevelProtocol {
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
        case .grade1: "intl_grade_1_name"
        case .grade2: "intl_grade_2_name"
        case .grade3: "intl_grade_3_name"
        case .grade4: "intl_grade_4_name"
        case .grade5: "intl_grade_5_name"
        case .grade6: "intl_grade_6_name"
        case .grade7: "intl_grade_7_name"
        case .grade8: "intl_grade_8_name"
        case .grade9: "intl_grade_9_name"
        case .grade10: "intl_grade_10_name"
        case .grade11: "intl_grade_11_name"
        case .grade12: "intl_grade_12_name"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .grade1: "intl_grade_1_short"
        case .grade2: "intl_grade_2_short"
        case .grade3: "intl_grade_3_short"
        case .grade4: "intl_grade_4_short"
        case .grade5: "intl_grade_5_short"
        case .grade6: "intl_grade_6_short"
        case .grade7: "intl_grade_7_short"
        case .grade8: "intl_grade_8_short"
        case .grade9: "intl_grade_9_short"
        case .grade10: "intl_grade_10_short"
        case .grade11: "intl_grade_11_short"
        case .grade12: "intl_grade_12_short"
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

// MARK: - InternationalSubject

/// 国际通用学科
public enum InternationalSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case language = "intl_language"         // Native Language
    case english = "intl_english"           // English
    case math = "intl_math"                 // Mathematics
    case science = "intl_science"           // Science
    case physics = "intl_physics"
    case chemistry = "intl_chemistry"
    case biology = "intl_biology"
    case history = "intl_history"
    case geography = "intl_geography"
    case socialStudies = "intl_social"
    case art = "intl_art"
    case music = "intl_music"
    case other = "intl_other"

    public var id: String { rawValue }
}

extension InternationalSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .language: "intl_subject_language"
        case .english: "intl_subject_english"
        case .math: "intl_subject_math"
        case .science: "intl_subject_science"
        case .physics: "intl_subject_physics"
        case .chemistry: "intl_subject_chemistry"
        case .biology: "intl_subject_biology"
        case .history: "intl_subject_history"
        case .geography: "intl_subject_geography"
        case .socialStudies: "intl_subject_social"
        case .art: "intl_subject_art"
        case .music: "intl_subject_music"
        case .other: "intl_subject_other"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .language: "intl_subject_language_short"
        case .english: "intl_subject_english_short"
        case .math: "intl_subject_math_short"
        case .science: "intl_subject_science_short"
        case .physics: "intl_subject_physics_short"
        case .chemistry: "intl_subject_chemistry_short"
        case .biology: "intl_subject_biology_short"
        case .history: "intl_subject_history_short"
        case .geography: "intl_subject_geography_short"
        case .socialStudies: "intl_subject_social_short"
        case .art: "intl_subject_art_short"
        case .music: "intl_subject_music_short"
        case .other: "intl_subject_other_short"
        }
    }

    public var category: any SubjectCategoryProtocol {
        switch self {
        case .language, .english:
            ChinaSubjectCategory.language
        case .math, .science, .physics, .chemistry, .biology:
            ChinaSubjectCategory.science
        case .history, .geography, .socialStudies:
            ChinaSubjectCategory.humanities
        case .art, .music, .other:
            ChinaSubjectCategory.other
        }
    }

    public var icon: String {
        switch self {
        case .language: "textformat"
        case .english: "a.circle"
        case .math: "function"
        case .science: "flask"
        case .physics: "atom"
        case .chemistry: "flask.fill"
        case .biology: "leaf"
        case .history: "clock.arrow.circlepath"
        case .geography: "globe"
        case .socialStudies: "building.columns"
        case .art: "paintpalette"
        case .music: "music.note"
        case .other: "ellipsis.circle"
        }
    }

    public var color: Color {
        switch self {
        case .language: .red
        case .english: .purple
        case .math: .blue
        case .science: .cyan
        case .physics: .indigo
        case .chemistry: .green
        case .biology: .mint
        case .history: .brown
        case .geography: .teal
        case .socialStudies: .orange
        case .art: .pink
        case .music: .yellow
        case .other: .gray
        }
    }

    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段：语言、数学
        case .language, .english, .math:
            [.primary, .middle, .high]
        // 小学+中学
        case .science, .socialStudies, .art, .music:
            [.primary, .middle]
        // 中学+高中
        case .physics, .chemistry, .biology, .geography, .history:
            [.middle, .high]
        // 全学段
        case .other:
            [.primary, .middle, .high]
        }
    }
}

// MARK: - InternationalEducationSystem

/// 国际通用教育体系
public struct InternationalEducationSystem: EducationSystemProtocol {
    public typealias GradeType = InternationalGrade
    public typealias SubjectType = InternationalSubject

    public let region: EducationRegion = .international
    public let name: String = "International"

    public var grades: [InternationalGrade] { InternationalGrade.allCases }
    public var subjects: [InternationalSubject] { InternationalSubject.allCases }

    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "intl_school_primary",
                startGrade: 1,
                endGrade: 6,
                icon: "backpack",
                color: .green
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "intl_school_middle",
                startGrade: 7,
                endGrade: 9,
                icon: "book",
                color: .blue
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "intl_school_high",
                startGrade: 10,
                endGrade: 12,
                icon: "graduationcap",
                color: .purple
            )
        ]
    }

    public init() {}
}
