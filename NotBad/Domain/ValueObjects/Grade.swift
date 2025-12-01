//
//  Grade.swift
//  NotBad
//
//  年级值对象 - K12教育（小学到高中）
//

import SwiftUI

// MARK: - Grade

/// 年级（K12：小学到高中共12个年级）
///
/// 完整覆盖 K12 教育体系的所有年级。
///
/// ## 年级列表
///
/// ### 小学（Primary）
/// - ``grade1`` ~ ``grade6``: 一年级到六年级
///
/// ### 初中（Junior）
/// - ``grade7`` ~ ``grade9``: 七年级到九年级
///
/// ### 高中（Senior）
/// - ``grade10`` ~ ``grade12``: 高一到高三
///
/// ## 使用示例
/// ```swift
/// let grade = Grade.grade9
/// print(grade.displayName)  // "九年级"
/// print(grade.shortLabel)   // "初三"
/// print(grade.stage)        // .junior
/// print(grade.order)        // 9
/// ```
enum Grade: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    // 幼儿园
    case kindergarten = "kindergarten"

    // 小学 (6年)
    /// 一年级
    case grade1 = "grade_1"
    /// 二年级
    case grade2 = "grade_2"
    /// 三年级
    case grade3 = "grade_3"
    /// 四年级
    case grade4 = "grade_4"
    /// 五年级
    case grade5 = "grade_5"
    /// 六年级
    case grade6 = "grade_6"

    // 初中 (3年)
    /// 七年级（初一）
    case grade7 = "grade_7"
    /// 八年级（初二）
    case grade8 = "grade_8"
    /// 九年级（初三）
    case grade9 = "grade_9"

    // 高中 (3年)
    /// 高一（十年级）
    case grade10 = "grade_10"
    /// 高二（十一年级）
    case grade11 = "grade_11"
    /// 高三（十二年级）
    case grade12 = "grade_12"

    // MARK: Identifiable

    nonisolated var id: String { rawValue }
}

// MARK: - Grade Display Properties

extension Grade {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .kindergarten: "grade_k"
        case .grade1: "grade_1"
        case .grade2: "grade_2"
        case .grade3: "grade_3"
        case .grade4: "grade_4"
        case .grade5: "grade_5"
        case .grade6: "grade_6"
        case .grade7: "grade_7"
        case .grade8: "grade_8"
        case .grade9: "grade_9"
        case .grade10: "grade_10"
        case .grade11: "grade_11"
        case .grade12: "grade_12"
        }
    }

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .kindergarten: "grade_k_short"
        case .grade1: "grade_1_short"
        case .grade2: "grade_2_short"
        case .grade3: "grade_3_short"
        case .grade4: "grade_4_short"
        case .grade5: "grade_5_short"
        case .grade6: "grade_6_short"
        case .grade7: "grade_7_short"
        case .grade8: "grade_8_short"
        case .grade9: "grade_9_short"
        case .grade10: "grade_10_short"
        case .grade11: "grade_11_short"
        case .grade12: "grade_12_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .kindergarten, .grade1, .grade2:
            "figure.child"
        case .grade3, .grade4, .grade5, .grade6:
            "figure.child.and.lock"
        case .grade7, .grade8, .grade9:
            "figure.stand"
        case .grade10, .grade11, .grade12:
            "graduationcap"
        }
    }

    /// 主题颜色（同学段渐变）
    nonisolated var color: Color {
        switch self {
        // 幼儿园：粉色系
        case .kindergarten: .pink
        // 小学：绿色系
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
}

// MARK: - Grade Classification

extension Grade {
    /// 学段分组
    nonisolated var stage: GradeStage {
        switch self {
        case .kindergarten, .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            .primary
        case .grade7, .grade8, .grade9:
            .junior
        case .grade10, .grade11, .grade12:
            .senior
        }
    }

    /// 年级序号（0-12）
    nonisolated var order: Int {
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

    /// 是否为毕业年级（六年级、九年级、高三）
    nonisolated var isGraduationYear: Bool {
        switch self {
        case .grade6, .grade9, .grade12: true
        default: false
        }
    }
}

// MARK: - Grade Factory Methods

extension Grade {
    /// 根据年级序号创建年级
    /// - Parameter order: 年级序号（1-12）
    /// - Returns: 对应的年级，无效序号返回 nil
    static func from(order: Int) -> Grade? {
        allCases.first { $0.order == order }
    }

    /// 获取指定学段的年级列表
    /// - Parameter stage: 学段
    /// - Returns: 该学段下的年级数组
    static func grades(for stage: GradeStage) -> [Grade] {
        allCases.filter { $0.stage == stage }
    }
}

// MARK: - Grade Comparable

extension Grade: Comparable {
    nonisolated static func < (lhs: Grade, rhs: Grade) -> Bool {
        lhs.order < rhs.order
    }
}

// MARK: - Grade CustomStringConvertible

extension Grade: CustomStringConvertible {
    nonisolated var description: String { displayName }
}

// MARK: - Grade Collections

extension Grade {
    /// 小学年级
    static let primaryGrades: [Grade] = [.kindergarten, .grade1, .grade2, .grade3, .grade4, .grade5, .grade6]

    /// 初中年级
    static let juniorGrades: [Grade] = [.grade7, .grade8, .grade9]

    /// 高中年级
    static let seniorGrades: [Grade] = [.grade10, .grade11, .grade12]

    /// 毕业年级
    static let graduationGrades: [Grade] = [.grade6, .grade9, .grade12]
}
