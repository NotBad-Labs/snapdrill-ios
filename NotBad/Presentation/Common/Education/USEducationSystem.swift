//
//  USEducationSystem.swift
//  NotBad
//
//  美国教育体系 (K-12)
//
//  Elementary School: Kindergarten - 5th grade (6年)
//  Middle School: 6th - 8th grade (3年)
//  High School: 9th - 12th grade (4年)
//
//  注：美国各州学制略有不同，这里采用最常见的 6-3-4 模式
//

import Foundation

// MARK: - USGrade

/// 美国年级 (K-12)
///
/// 覆盖美国K12教育的所有年级，包括 Kindergarten。
public enum USGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, GradeLevelProtocol {
    // Elementary School
    case kindergarten = "kindergarten"
    case grade1 = "grade_1"
    case grade2 = "grade_2"
    case grade3 = "grade_3"
    case grade4 = "grade_4"
    case grade5 = "grade_5"
    // Middle School
    case grade6 = "grade_6"
    case grade7 = "grade_7"
    case grade8 = "grade_8"
    // High School
    case grade9 = "grade_9"   // Freshman
    case grade10 = "grade_10" // Sophomore
    case grade11 = "grade_11" // Junior
    case grade12 = "grade_12" // Senior

    // MARK: - GradeLevelProtocol

    public var id: String { rawValue }

    public var order: Int {
        switch self {
        case .kindergarten: 0
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
        case .kindergarten, .grade1, .grade2, .grade3, .grade4, .grade5:
            .primary
        case .grade6, .grade7, .grade8:
            .middle
        case .grade9, .grade10, .grade11, .grade12:
            .high
        }
    }

    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .kindergarten: "us_grade_k"
        case .grade1: "us_grade_1"
        case .grade2: "us_grade_2"
        case .grade3: "us_grade_3"
        case .grade4: "us_grade_4"
        case .grade5: "us_grade_5"
        case .grade6: "us_grade_6"
        case .grade7: "us_grade_7"
        case .grade8: "us_grade_8"
        case .grade9: "us_grade_9"
        case .grade10: "us_grade_10"
        case .grade11: "us_grade_11"
        case .grade12: "us_grade_12"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .kindergarten: "us_grade_k_short"
        case .grade1: "us_grade_1_short"
        case .grade2: "us_grade_2_short"
        case .grade3: "us_grade_3_short"
        case .grade4: "us_grade_4_short"
        case .grade5: "us_grade_5_short"
        case .grade6: "us_grade_6_short"
        case .grade7: "us_grade_7_short"
        case .grade8: "us_grade_8_short"
        case .grade9: "us_grade_9_short"
        case .grade10: "us_grade_10_short"
        case .grade11: "us_grade_11_short"
        case .grade12: "us_grade_12_short"
        }
    }

    /// 高中年级别名
    public var highSchoolAlias: String? {
        switch self {
        case .grade9: "Freshman"
        case .grade10: "Sophomore"
        case .grade11: "Junior"
        case .grade12: "Senior"
        default: nil
        }
    }

    public var icon: String {
        switch self {
        case .kindergarten:
            "figure.child"
        case .grade1, .grade2, .grade3:
            "figure.child"
        case .grade4, .grade5:
            "figure.child.and.lock"
        case .grade6, .grade7, .grade8:
            "figure.stand"
        case .grade9, .grade10, .grade11, .grade12:
            "graduationcap"
        }
    }


    /// 根据序号创建年级
    public static func from(order: Int) -> USGrade? {
        allCases.first { $0.order == order }
    }
}

// MARK: - USSubjectCategory

/// 美国学科分类
public enum USSubjectCategory: String, Sendable, CaseIterable, Codable, Hashable, Identifiable, SubjectCategoryProtocol {
    case ela = "ela"        // 英语语言艺术
    case math = "math"                  // 数学
    case science = "science"                   // 科学
    case socialStudies = "social_studies"      // 社会研究
    case foreignLanguage = "foreign_language"  // 外语
    case electives = "electives"               // 选修
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .ela: "us_subject_category_ela"
        case .math: "us_subject_category_math"
        case .science: "us_subject_category_science"
        case .socialStudies: "us_subject_category_social_studies"
        case .foreignLanguage: "us_subject_category_foreign_language"
        case .electives: "us_subject_category_electives"
        case .other: "us_subject_category_other"
        }
    }

    public var icon: String {
        switch self {
        case .ela: "textformat"
        case .math: "function"
        case .science: "flask"
        case .socialStudies: "globe.americas"
        case .foreignLanguage: "globe"
        case .electives: "star"
        case .other: "ellipsis.circle"
        }
    }

}

// MARK: - USSubject

/// 美国学科
///
/// 覆盖美国K12教育的主要学科。
public enum USSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // ELA
    case english = "english"
    case reading = "reading"
    case writing = "writing"
    case literature = "literature"

    // Math
    case math = "math"
    case algebra = "algebra"
    case geometry = "geometry"
    case calculus = "calculus"
    case statistics = "statistics"

    // Science
    case generalScience = "general_science"
    case biology = "biology"
    case chemistry = "chemistry"
    case physics = "physics"
    case earthScience = "earth_science"
    case environmentalScience = "environmental_science"

    // Social Studies
    case usHistory = "us_history"
    case worldHistory = "world_history"
    case geography = "geography"
    case civics = "civics"
    case economics = "economics"
    case government = "government"

    // Foreign Language
    case spanish = "spanish"
    case french = "french"
    case german = "german"
    case chinese = "chinese"
    case japanese = "japanese"

    // Electives
    case art = "art"
    case music = "music"
    case computerScience = "computer_science"
    case physicalEducation = "pe"
    case health = "health"

    // Other
    case other = "other"

    public var id: String { rawValue }
}

// MARK: - USSubject SubjectProtocol

extension USSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: localizationKey)
    }

    private var localizationKey: String.LocalizationValue {
        switch self {
        case .english: "us_subject_english"
        case .reading: "us_subject_reading"
        case .writing: "us_subject_writing"
        case .literature: "us_subject_literature"
        case .math: "us_subject_math"
        case .algebra: "us_subject_algebra"
        case .geometry: "us_subject_geometry"
        case .calculus: "us_subject_calculus"
        case .statistics: "us_subject_statistics"
        case .generalScience: "us_subject_general_science"
        case .biology: "us_subject_biology"
        case .chemistry: "us_subject_chemistry"
        case .physics: "us_subject_physics"
        case .earthScience: "us_subject_earth_science"
        case .environmentalScience: "us_subject_env_science"
        case .usHistory: "us_subject_us_history"
        case .worldHistory: "us_subject_world_history"
        case .geography: "us_subject_geography"
        case .civics: "us_subject_civics"
        case .economics: "us_subject_economics"
        case .government: "us_subject_government"
        case .spanish: "us_subject_spanish"
        case .french: "us_subject_french"
        case .german: "us_subject_german"
        case .chinese: "us_subject_chinese"
        case .japanese: "us_subject_japanese"
        case .art: "us_subject_art"
        case .music: "us_subject_music"
        case .computerScience: "us_subject_cs"
        case .physicalEducation: "us_subject_pe"
        case .health: "us_subject_health"
        case .other: "us_subject_other"
        }
    }

    public var shortLabel: String {
        String(localized: shortLabelKey)
    }

    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .english: "us_subject_english_short"
        case .reading: "us_subject_reading_short"
        case .writing: "us_subject_writing_short"
        case .literature: "us_subject_literature_short"
        case .math: "us_subject_math_short"
        case .algebra: "us_subject_algebra_short"
        case .geometry: "us_subject_geometry_short"
        case .calculus: "us_subject_calculus_short"
        case .statistics: "us_subject_statistics_short"
        case .generalScience: "us_subject_general_science_short"
        case .biology: "us_subject_biology_short"
        case .chemistry: "us_subject_chemistry_short"
        case .physics: "us_subject_physics_short"
        case .earthScience: "us_subject_earth_science_short"
        case .environmentalScience: "us_subject_env_science_short"
        case .usHistory: "us_subject_us_history_short"
        case .worldHistory: "us_subject_world_history_short"
        case .geography: "us_subject_geography_short"
        case .civics: "us_subject_civics_short"
        case .economics: "us_subject_economics_short"
        case .government: "us_subject_government_short"
        case .spanish: "us_subject_spanish_short"
        case .french: "us_subject_french_short"
        case .german: "us_subject_german_short"
        case .chinese: "us_subject_chinese_short"
        case .japanese: "us_subject_japanese_short"
        case .art: "us_subject_art_short"
        case .music: "us_subject_music_short"
        case .computerScience: "us_subject_cs_short"
        case .physicalEducation: "us_subject_pe_short"
        case .health: "us_subject_health_short"
        case .other: "us_subject_other_short"
        }
    }

    public var category: any SubjectCategoryProtocol {
        usCategory
    }

    public var usCategory: USSubjectCategory {
        switch self {
        case .english, .reading, .writing, .literature:
            .ela
        case .math, .algebra, .geometry, .calculus, .statistics:
            .math
        case .generalScience, .biology, .chemistry, .physics, .earthScience, .environmentalScience:
            .science
        case .usHistory, .worldHistory, .geography, .civics, .economics, .government:
            .socialStudies
        case .spanish, .french, .german, .chinese, .japanese:
            .foreignLanguage
        case .art, .music, .computerScience, .physicalEducation, .health:
            .electives
        case .other:
            .other
        }
    }

    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段基础科目
        case .english, .reading, .writing, .math, .generalScience, .art, .music, .physicalEducation:
            [.primary, .middle, .high]
        // 初中+高中
        case .algebra, .biology, .usHistory, .worldHistory, .geography, .civics, .health:
            [.middle, .high]
        // 仅高中
        case .literature, .geometry, .calculus, .statistics,
             .chemistry, .physics, .earthScience, .environmentalScience,
             .economics, .government,
             .spanish, .french, .german, .chinese, .japanese,
             .computerScience:
            [.high]
        case .other:
            [.primary, .middle, .high]
        }
    }

    public var icon: String {
        switch self {
        case .english, .reading, .writing, .literature: "textformat"
        case .math, .algebra, .geometry, .calculus, .statistics: "function"
        case .generalScience: "testtube.2"
        case .biology: "leaf"
        case .chemistry: "flask"
        case .physics: "atom"
        case .earthScience, .environmentalScience: "globe"
        case .usHistory, .worldHistory: "clock.arrow.circlepath"
        case .geography: "globe.americas"
        case .civics, .government: "building.columns"
        case .economics: "chart.line.uptrend.xyaxis"
        case .spanish, .french, .german, .chinese, .japanese: "globe"
        case .art: "paintpalette"
        case .music: "music.note"
        case .computerScience: "desktopcomputer"
        case .physicalEducation: "figure.run"
        case .health: "heart"
        case .other: "ellipsis.circle"
        }
    }

}

// MARK: - USEducationSystem

/// 美国教育体系
///
/// 实现美国 K-12 (6-3-4) 学制的完整配置。
public struct USEducationSystem: EducationSystemProtocol, Sendable {
    public typealias GradeType = USGrade
    public typealias SubjectType = USSubject

    public let region = EducationRegion.usa

    public var name: String {
        String(localized: "us_education_system_name")
    }

    public var grades: [USGrade] {
        USGrade.allCases
    }

    public var subjects: [USSubject] {
        USSubject.allCases
    }

    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "us_school_level_elementary",
                startGrade: 0,  // Kindergarten
                endGrade: 5,
                icon: "figure.child"
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "us_school_level_middle",
                startGrade: 6,
                endGrade: 8,
                icon: "figure.stand"
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "us_school_level_high",
                startGrade: 9,
                endGrade: 12,
                icon: "graduationcap"
            )
        ]
    }

    public init() {}

    // MARK: - 美国特有的学科组合

    /// 核心科目 (Core Subjects)
    public var coreSubjects: [USSubject] {
        [.english, .math, .generalScience, .usHistory]
    }

    /// SAT 相关科目
    public var satSubjects: [USSubject] {
        [.english, .reading, .writing, .math, .algebra, .geometry]
    }

    /// AP 常见科目
    public var apSubjects: [USSubject] {
        [.calculus, .statistics, .biology, .chemistry, .physics,
         .usHistory, .worldHistory, .government, .economics,
         .english, .literature, .computerScience]
    }

    /// STEM 科目
    public var stemSubjects: [USSubject] {
        [.math, .algebra, .geometry, .calculus, .statistics,
         .generalScience, .biology, .chemistry, .physics,
         .computerScience]
    }
}
