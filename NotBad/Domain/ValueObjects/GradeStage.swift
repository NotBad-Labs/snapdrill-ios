//
//  GradeStage.swift
//  NotBad
//
//  学段值对象（小学/初中/高中）
//

import Foundation

// MARK: - GradeStage

/// 学段（小学/初中/高中）
///
/// 表示 K12 教育的三个主要学段，用于筛选学科和题目。
///
/// ## 学段说明
/// - ``primary``: 小学（1-6年级）
/// - ``junior``: 初中（7-9年级）
/// - ``senior``: 高中（10-12年级）
///
/// ## 使用示例
/// ```swift
/// let stage = GradeStage.junior
/// print(stage.displayName)     // "初中"
/// print(stage.gradeRange)      // "7-9年级"
/// print(stage.grades)          // [.grade7, .grade8, .grade9]
/// ```
enum GradeStage: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    /// 小学（1-6年级）
    case primary = "primary"

    /// 初中（7-9年级）
    case junior = "junior"

    /// 高中（10-12年级）
    case senior = "senior"

    // MARK: Identifiable

    nonisolated var id: String { rawValue }
}

// MARK: - GradeStage Display Properties

extension GradeStage {
    /// 显示名称
    nonisolated var displayName: String {
        String(localized: localizationKey)
    }

    /// 本地化键值
    private var localizationKey: String.LocalizationValue {
        switch self {
        case .primary: "grade_stage_primary"
        case .junior: "grade_stage_junior"
        case .senior: "grade_stage_senior"
        }
    }

    /// 简短标签
    nonisolated var shortLabel: String {
        String(localized: shortLabelKey)
    }

    /// 简短标签本地化键值
    private var shortLabelKey: String.LocalizationValue {
        switch self {
        case .primary: "grade_stage_primary_short"
        case .junior: "grade_stage_junior_short"
        case .senior: "grade_stage_senior_short"
        }
    }

    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .primary: "figure.child"
        case .junior: "figure.stand"
        case .senior: "graduationcap"
        }
    }
}

// MARK: - GradeStage Grade Information

extension GradeStage {
    /// 年级范围描述
    nonisolated var gradeRange: String {
        String(localized: gradeRangeKey)
    }

    /// 年级范围本地化键值
    private var gradeRangeKey: String.LocalizationValue {
        switch self {
        case .primary: "grade_stage_primary_range"
        case .junior: "grade_stage_junior_range"
        case .senior: "grade_stage_senior_range"
        }
    }

    /// 该学段包含的年级
    nonisolated var grades: [Grade] {
        Grade.allCases.filter { $0.stage == self }
    }

    /// 年级数量
    nonisolated var gradeCount: Int {
        switch self {
        case .primary: 7 // 包含幼儿园
        case .junior: 3
        case .senior: 3
        }
    }

    /// 起始年级序号
    nonisolated var firstGradeOrder: Int {
        switch self {
        case .primary: 0 // 包含幼儿园
        case .junior: 7
        case .senior: 10
        }
    }

    /// 结束年级序号
    nonisolated var lastGradeOrder: Int {
        switch self {
        case .primary: 6
        case .junior: 9
        case .senior: 12
        }
    }
}

// MARK: - GradeStage Factory Methods

extension GradeStage {
    /// 根据年级序号获取学段
    /// - Parameter order: 年级序号（0-12）
    /// - Returns: 对应的学段，无效序号返回 nil
    static func from(gradeOrder order: Int) -> GradeStage? {
        switch order {
        case 0...6: .primary
        case 7...9: .junior
        case 10...12: .senior
        default: nil
        }
    }

    /// 检查年级序号是否属于此学段
    /// - Parameter order: 年级序号
    /// - Returns: 是否属于此学段
    nonisolated func contains(gradeOrder order: Int) -> Bool {
        order >= firstGradeOrder && order <= lastGradeOrder
    }
}

// MARK: - GradeStage Comparable

extension GradeStage: Comparable {
    nonisolated static func < (lhs: GradeStage, rhs: GradeStage) -> Bool {
        lhs.firstGradeOrder < rhs.firstGradeOrder
    }
}

// MARK: - GradeStage CustomStringConvertible

extension GradeStage: CustomStringConvertible {
    nonisolated var description: String { displayName }
}
