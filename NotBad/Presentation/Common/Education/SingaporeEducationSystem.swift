//
//  SingaporeEducationSystem.swift
//  NotBad
//
//  新加坡教育体系（6+4+2学制）
//

import Foundation

// MARK: - SingaporeGrade

/// 新加坡年级
public enum SingaporeGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // Primary School (6年)
    case primary1 = "sg_p1"
    case primary2 = "sg_p2"
    case primary3 = "sg_p3"
    case primary4 = "sg_p4"
    case primary5 = "sg_p5"
    case primary6 = "sg_p6"  // PSLE

    // Secondary School (4年)
    case secondary1 = "sg_s1"
    case secondary2 = "sg_s2"
    case secondary3 = "sg_s3"
    case secondary4 = "sg_s4"  // O-Level

    // Junior College (2年)
    case jc1 = "sg_jc1"
    case jc2 = "sg_jc2"  // A-Level

    public var id: String { rawValue }
}

extension SingaporeGrade: GradeLevelProtocol {
    public var order: Int {
        switch self {
        case .primary1: 1
        case .primary2: 2
        case .primary3: 3
        case .primary4: 4
        case .primary5: 5
        case .primary6: 6
        case .secondary1: 7
        case .secondary2: 8
        case .secondary3: 9
        case .secondary4: 10
        case .jc1: 11
        case .jc2: 12
        }
    }

    public var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .primary1: "sg_grade_p1_name"
        case .primary2: "sg_grade_p2_name"
        case .primary3: "sg_grade_p3_name"
        case .primary4: "sg_grade_p4_name"
        case .primary5: "sg_grade_p5_name"
        case .primary6: "sg_grade_p6_name"
        case .secondary1: "sg_grade_s1_name"
        case .secondary2: "sg_grade_s2_name"
        case .secondary3: "sg_grade_s3_name"
        case .secondary4: "sg_grade_s4_name"
        case .jc1: "sg_grade_jc1_name"
        case .jc2: "sg_grade_jc2_name"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .primary1: "sg_grade_p1_short"
        case .primary2: "sg_grade_p2_short"
        case .primary3: "sg_grade_p3_short"
        case .primary4: "sg_grade_p4_short"
        case .primary5: "sg_grade_p5_short"
        case .primary6: "sg_grade_p6_short"
        case .secondary1: "sg_grade_s1_short"
        case .secondary2: "sg_grade_s2_short"
        case .secondary3: "sg_grade_s3_short"
        case .secondary4: "sg_grade_s4_short"
        case .jc1: "sg_grade_jc1_short"
        case .jc2: "sg_grade_jc2_short"
        }
    }

    public var schoolLevel: SchoolLevel {
        switch self {
        case .primary1, .primary2, .primary3, .primary4, .primary5, .primary6:
            .primary
        case .secondary1, .secondary2, .secondary3, .secondary4:
            .middle
        case .jc1, .jc2:
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

}

// MARK: - SingaporeSubject

/// 新加坡学科
public enum SingaporeSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case english = "sg_english"
    case chinese = "sg_chinese"         // 华文
    case malay = "sg_malay"             // 马来文
    case tamil = "sg_tamil"             // 淡米尔文
    case math = "sg_math"
    case science = "sg_science"
    case physics = "sg_physics"
    case chemistry = "sg_chemistry"
    case biology = "sg_biology"
    case geography = "sg_geography"
    case history = "sg_history"
    case socialStudies = "sg_social"
    case other = "sg_other"

    public var id: String { rawValue }
}

extension SingaporeSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: displayNameKey)
    }

    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .english: "sg_subject_english"
        case .chinese: "sg_subject_chinese"
        case .malay: "sg_subject_malay"
        case .tamil: "sg_subject_tamil"
        case .math: "sg_subject_math"
        case .science: "sg_subject_science"
        case .physics: "sg_subject_physics"
        case .chemistry: "sg_subject_chemistry"
        case .biology: "sg_subject_biology"
        case .geography: "sg_subject_geography"
        case .history: "sg_subject_history"
        case .socialStudies: "sg_subject_social"
        case .other: "sg_subject_other"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .english: "sg_subject_english_short"
        case .chinese: "sg_subject_chinese_short"
        case .malay: "sg_subject_malay_short"
        case .tamil: "sg_subject_tamil_short"
        case .math: "sg_subject_math_short"
        case .science: "sg_subject_science_short"
        case .physics: "sg_subject_physics_short"
        case .chemistry: "sg_subject_chemistry_short"
        case .biology: "sg_subject_biology_short"
        case .geography: "sg_subject_geography_short"
        case .history: "sg_subject_history_short"
        case .socialStudies: "sg_subject_social_short"
        case .other: "sg_subject_other_short"
        }
    }

    public var category: any SubjectCategoryProtocol {
        switch self {
        case .english, .chinese, .malay, .tamil:
            ChinaSubjectCategory.language
        case .math, .science, .physics, .chemistry, .biology:
            ChinaSubjectCategory.science
        case .geography, .history, .socialStudies:
            ChinaSubjectCategory.humanities
        case .other:
            ChinaSubjectCategory.other
        }
    }

    public var icon: String {
        switch self {
        case .english: "a.circle"
        case .chinese: "character.zh"
        case .malay: "character"
        case .tamil: "character"
        case .math: "function"
        case .science: "flask"
        case .physics: "atom"
        case .chemistry: "flask.fill"
        case .biology: "leaf"
        case .geography: "globe.asia.australia"
        case .history: "clock.arrow.circlepath"
        case .socialStudies: "building.columns"
        case .other: "ellipsis.circle"
        }
    }


    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段：英语、数学、母语
        case .english, .math, .chinese, .malay, .tamil:
            [.primary, .middle, .high]
        // 小学+中学
        case .science, .socialStudies:
            [.primary, .middle]
        // 中学+JC
        case .physics, .chemistry, .biology, .geography, .history:
            [.middle, .high]
        // 全学段
        case .other:
            [.primary, .middle, .high]
        }
    }
}

// MARK: - SingaporeEducationSystem

/// 新加坡教育体系
public struct SingaporeEducationSystem: EducationSystemProtocol {
    public typealias GradeType = SingaporeGrade
    public typealias SubjectType = SingaporeSubject

    public let region: EducationRegion = .singapore
    public let name: String = "Singapore Education"

    public var grades: [SingaporeGrade] { SingaporeGrade.allCases }
    public var subjects: [SingaporeSubject] { SingaporeSubject.allCases }

    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "sg_school_primary",
                startGrade: 1,
                endGrade: 6,
                icon: "backpack"
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "sg_school_secondary",
                startGrade: 7,
                endGrade: 10,
                icon: "book"
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "sg_school_jc",
                startGrade: 11,
                endGrade: 12,
                icon: "graduationcap"
            )
        ]
    }

    public init() {}
}
