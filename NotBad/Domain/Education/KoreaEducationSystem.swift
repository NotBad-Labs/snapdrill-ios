//
//  KoreaEducationSystem.swift
//  NotBad
//
//  韩国教育体系（6+3+3学制）
//

import Foundation
import SwiftUI

// MARK: - KoreaGrade

/// 韩国年级
public enum KoreaGrade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 초등학교 (6年)
    case grade1 = "kr_grade_1"
    case grade2 = "kr_grade_2"
    case grade3 = "kr_grade_3"
    case grade4 = "kr_grade_4"
    case grade5 = "kr_grade_5"
    case grade6 = "kr_grade_6"
    
    // 중학교 (3年)
    case grade7 = "kr_grade_7"
    case grade8 = "kr_grade_8"
    case grade9 = "kr_grade_9"
    
    // 고등학교 (3年)
    case grade10 = "kr_grade_10"
    case grade11 = "kr_grade_11"
    case grade12 = "kr_grade_12"
    
    public var id: String { rawValue }
}

extension KoreaGrade: GradeLevelProtocol {
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
        case .grade1: "kr_grade_1_name"
        case .grade2: "kr_grade_2_name"
        case .grade3: "kr_grade_3_name"
        case .grade4: "kr_grade_4_name"
        case .grade5: "kr_grade_5_name"
        case .grade6: "kr_grade_6_name"
        case .grade7: "kr_grade_7_name"
        case .grade8: "kr_grade_8_name"
        case .grade9: "kr_grade_9_name"
        case .grade10: "kr_grade_10_name"
        case .grade11: "kr_grade_11_name"
        case .grade12: "kr_grade_12_name"
        }
    }
    
    public var shortLabel: String {
        String(localized: shortLabelKey)
    }
    
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .grade1: "kr_grade_1_short"
        case .grade2: "kr_grade_2_short"
        case .grade3: "kr_grade_3_short"
        case .grade4: "kr_grade_4_short"
        case .grade5: "kr_grade_5_short"
        case .grade6: "kr_grade_6_short"
        case .grade7: "kr_grade_7_short"
        case .grade8: "kr_grade_8_short"
        case .grade9: "kr_grade_9_short"
        case .grade10: "kr_grade_10_short"
        case .grade11: "kr_grade_11_short"
        case .grade12: "kr_grade_12_short"
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

// MARK: - KoreaSubject

/// 韩国学科
public enum KoreaSubject: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case korean = "kr_korean"           // 국어
    case math = "kr_math"               // 수학
    case english = "kr_english"         // 영어
    case science = "kr_science"         // 과학
    case socialStudies = "kr_social"    // 사회
    case physics = "kr_physics"         // 물리
    case chemistry = "kr_chemistry"     // 화학
    case biology = "kr_biology"         // 생물
    case geography = "kr_geography"     // 지리
    case history = "kr_history"         // 역사/한국사
    case ethics = "kr_ethics"           // 도덕/윤리
    case other = "kr_other"
    
    public var id: String { rawValue }
}

extension KoreaSubject: SubjectProtocol {
    public var displayName: String {
        String(localized: displayNameKey)
    }
    
    private var displayNameKey: String.LocalizationValue {
        switch self {
        case .korean: "kr_subject_korean"
        case .math: "kr_subject_math"
        case .english: "kr_subject_english"
        case .science: "kr_subject_science"
        case .socialStudies: "kr_subject_social"
        case .physics: "kr_subject_physics"
        case .chemistry: "kr_subject_chemistry"
        case .biology: "kr_subject_biology"
        case .geography: "kr_subject_geography"
        case .history: "kr_subject_history"
        case .ethics: "kr_subject_ethics"
        case .other: "kr_subject_other"
        }
    }
    
    public var shortLabel: String {
        String(localized: shortLabelKey)
    }
    
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .korean: "kr_subject_korean_short"
        case .math: "kr_subject_math_short"
        case .english: "kr_subject_english_short"
        case .science: "kr_subject_science_short"
        case .socialStudies: "kr_subject_social_short"
        case .physics: "kr_subject_physics_short"
        case .chemistry: "kr_subject_chemistry_short"
        case .biology: "kr_subject_biology_short"
        case .geography: "kr_subject_geography_short"
        case .history: "kr_subject_history_short"
        case .ethics: "kr_subject_ethics_short"
        case .other: "kr_subject_other_short"
        }
    }
    
    public var category: any SubjectCategoryProtocol {
        switch self {
        case .korean, .english:
            ChinaSubjectCategory.language
        case .math, .science, .physics, .chemistry, .biology:
            ChinaSubjectCategory.science
        case .socialStudies, .geography, .history, .ethics:
            ChinaSubjectCategory.humanities
        case .other:
            ChinaSubjectCategory.other
        }
    }
    
    public var icon: String {
        switch self {
        case .korean: "character.ko"
        case .math: "function"
        case .english: "a.circle"
        case .science: "flask"
        case .socialStudies: "building.columns"
        case .physics: "atom"
        case .chemistry: "flask.fill"
        case .biology: "leaf"
        case .geography: "globe.asia.australia"
        case .history: "clock.arrow.circlepath"
        case .ethics: "heart.circle"
        case .other: "ellipsis.circle"
        }
    }
    
    public var color: Color {
        switch self {
        case .korean: .red
        case .math: .blue
        case .english: .purple
        case .science: .cyan
        case .socialStudies: .orange
        case .physics: .indigo
        case .chemistry: .green
        case .biology: .mint
        case .geography: .teal
        case .history: .brown
        case .ethics: .pink
        case .other: .gray
        }
    }
    
    public var applicableLevels: [SchoolLevel] {
        switch self {
        // 全学段：国语、数学、英语
        case .korean, .math, .english:
            [.primary, .middle, .high]
        // 小学+初中
        case .science, .socialStudies, .ethics:
            [.primary, .middle]
        // 初中+高中
        case .physics, .chemistry, .biology, .geography, .history:
            [.middle, .high]
        // 全学段
        case .other:
            [.primary, .middle, .high]
        }
    }
}

// MARK: - KoreaEducationSystem

/// 韩国教育体系
public struct KoreaEducationSystem: EducationSystemProtocol {
    public typealias GradeType = KoreaGrade
    public typealias SubjectType = KoreaSubject
    
    public let region: EducationRegion = .korea
    public let name: String = "한국 교육"
    
    public var grades: [KoreaGrade] { KoreaGrade.allCases }
    public var subjects: [KoreaSubject] { KoreaSubject.allCases }
    
    public var schoolLevels: [SchoolLevelConfiguration] {
        [
            SchoolLevelConfiguration(
                level: .primary,
                nameKey: "kr_school_primary",
                startGrade: 1,
                endGrade: 6,
                icon: "backpack",
                color: .green
            ),
            SchoolLevelConfiguration(
                level: .middle,
                nameKey: "kr_school_middle",
                startGrade: 7,
                endGrade: 9,
                icon: "book",
                color: .blue
            ),
            SchoolLevelConfiguration(
                level: .high,
                nameKey: "kr_school_high",
                startGrade: 10,
                endGrade: 12,
                icon: "graduationcap",
                color: .purple
            )
        ]
    }
    
    public init() {}
}
