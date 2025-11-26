//
//  Grade.swift
//  NotBad
//
//  年级值对象 - K12教育（小学到高中）
//

import SwiftUI

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
    case primary = "小学"
    
    /// 初中（7-9年级）
    case junior = "初中"
    
    /// 高中（10-12年级）
    case senior = "高中"
    
    // MARK: Identifiable
    
    nonisolated var id: String { rawValue }
}

// MARK: - GradeStage Display Properties

extension GradeStage {
    /// 显示名称
    nonisolated var displayName: String { rawValue }
    
    /// 简短标签
    nonisolated var shortLabel: String {
        switch self {
        case .primary: "小"
        case .junior: "初"
        case .senior: "高"
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
    
    /// 主题颜色
    nonisolated var color: Color {
        switch self {
        case .primary: .green
        case .junior: .orange
        case .senior: .purple
        }
    }
}

// MARK: - GradeStage Grade Information

extension GradeStage {
    /// 年级范围描述
    nonisolated var gradeRange: String {
        switch self {
        case .primary: "1-6年级"
        case .junior: "7-9年级"
        case .senior: "10-12年级"
        }
    }
    
    /// 该学段包含的年级
    nonisolated var grades: [Grade] {
        Grade.allCases.filter { $0.stage == self }
    }
    
    /// 年级数量
    nonisolated var gradeCount: Int {
        switch self {
        case .primary: 6
        case .junior: 3
        case .senior: 3
        }
    }
    
    /// 起始年级序号
    nonisolated var firstGradeOrder: Int {
        switch self {
        case .primary: 1
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
    /// - Parameter order: 年级序号（1-12）
    /// - Returns: 对应的学段，无效序号返回 nil
    static func from(gradeOrder order: Int) -> GradeStage? {
        switch order {
        case 1...6: .primary
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
    // 小学 (6年)
    /// 一年级
    case grade1 = "一年级"
    /// 二年级
    case grade2 = "二年级"
    /// 三年级
    case grade3 = "三年级"
    /// 四年级
    case grade4 = "四年级"
    /// 五年级
    case grade5 = "五年级"
    /// 六年级
    case grade6 = "六年级"
    
    // 初中 (3年)
    /// 七年级（初一）
    case grade7 = "七年级"
    /// 八年级（初二）
    case grade8 = "八年级"
    /// 九年级（初三）
    case grade9 = "九年级"
    
    // 高中 (3年)
    /// 高一（十年级）
    case grade10 = "高一"
    /// 高二（十一年级）
    case grade11 = "高二"
    /// 高三（十二年级）
    case grade12 = "高三"
    
    // MARK: Identifiable
    
    nonisolated var id: String { rawValue }
}

// MARK: - Grade Display Properties

extension Grade {
    /// 显示名称
    nonisolated var displayName: String { rawValue }
    
    /// 简短标签
    nonisolated var shortLabel: String {
        switch self {
        case .grade1: "小一"
        case .grade2: "小二"
        case .grade3: "小三"
        case .grade4: "小四"
        case .grade5: "小五"
        case .grade6: "小六"
        case .grade7: "初一"
        case .grade8: "初二"
        case .grade9: "初三"
        case .grade10: "高一"
        case .grade11: "高二"
        case .grade12: "高三"
        }
    }
    
    /// SF Symbol 图标名称
    nonisolated var icon: String {
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
    
    /// 主题颜色（同学段渐变）
    nonisolated var color: Color {
        switch self {
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
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            .primary
        case .grade7, .grade8, .grade9:
            .junior
        case .grade10, .grade11, .grade12:
            .senior
        }
    }
    
    /// 年级序号（1-12）
    nonisolated var order: Int {
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
    static let primaryGrades: [Grade] = [.grade1, .grade2, .grade3, .grade4, .grade5, .grade6]
    
    /// 初中年级
    static let juniorGrades: [Grade] = [.grade7, .grade8, .grade9]
    
    /// 高中年级
    static let seniorGrades: [Grade] = [.grade10, .grade11, .grade12]
    
    /// 毕业年级
    static let graduationGrades: [Grade] = [.grade6, .grade9, .grade12]
}
