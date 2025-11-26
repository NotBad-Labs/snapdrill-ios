//
//  MasteryLevel.swift
//  NotBad
//
//  掌握程度值对象 - 5级制
//

import SwiftUI

// MARK: - MasteryLevel

/// 错题掌握程度（5级制）
///
/// 类似5星评分系统，用于追踪学生对错题的掌握程度。
/// 复习间隔计算由 ``ReviewInterval`` 负责。
///
/// ## 掌握等级
/// - ``none``: ⭐ 完全不会 - 需要重新学习基础概念
/// - ``glimpse``: ⭐⭐ 一知半解 - 看答案后能懂，但自己做不出来
/// - ``partial``: ⭐⭐⭐ 似懂非懂 - 能做对但不确定
/// - ``good``: ⭐⭐⭐⭐ 基本掌握 - 能独立完成
/// - ``mastered``: ⭐⭐⭐⭐⭐ 完全掌握 - 能举一反三
///
/// ## 使用示例
/// ```swift
/// let level = MasteryLevel.partial
/// print(level.displayName)    // "似懂非懂"
/// print(level.stars)          // 3
/// print(level.needsReview)    // true
/// print(level.reviewPriority) // 3
/// ```
enum MasteryLevel: Int, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    /// 完全不会 - 需要重新学习基础概念
    case none = 0
    /// 一知半解 - 看答案后能懂，但自己做不出来
    case glimpse = 1
    /// 似懂非懂 - 能做对但不确定，解题思路不清晰
    case partial = 2
    /// 基本掌握 - 能独立完成，偶尔会粗心出错
    case good = 3
    /// 完全掌握 - 完全掌握，能举一反三解决变式题
    case mastered = 4
    
    // MARK: Identifiable
    
    nonisolated var id: Int { rawValue }
}

// MARK: - MasteryLevel Display Properties

extension MasteryLevel {
    /// 显示名称
    nonisolated var displayName: String {
        switch self {
        case .none: "不会"
        case .glimpse: "一知半解"
        case .partial: "似懂非懂"
        case .good: "基本掌握"
        case .mastered: "完全掌握"
        }
    }
    
    /// 简短标签
    nonisolated var shortLabel: String {
        switch self {
        case .none: "不会"
        case .glimpse: "半解"
        case .partial: "似懂"
        case .good: "掌握"
        case .mastered: "精通"
        }
    }
    
    /// 详细描述
    nonisolated var detailText: String {
        switch self {
        case .none: "完全不会，需要重新学习基础概念"
        case .glimpse: "看答案后能懂，但自己做不出来"
        case .partial: "能做对但不确定，解题思路不清晰"
        case .good: "能独立完成，偶尔会粗心出错"
        case .mastered: "完全掌握，能举一反三解决变式题"
        }
    }
}

// MARK: - MasteryLevel Visual Properties

extension MasteryLevel {
    /// SF Symbol 图标名称
    nonisolated var icon: String {
        switch self {
        case .none: "xmark.circle.fill"
        case .glimpse: "eye.fill"
        case .partial: "questionmark.circle.fill"
        case .good: "checkmark.circle.fill"
        case .mastered: "star.circle.fill"
        }
    }
    
    /// 主题颜色（红→橙→黄→薄荷→绿 渐进）
    nonisolated var color: Color {
        switch self {
        case .none: Color.brand.error
        case .glimpse: Color.brand.warning
        case .partial: .yellow
        case .good: .mint
        case .mastered: Color.brand.success
        }
    }
    
    /// 星级（1-5）
    nonisolated var stars: Int { rawValue + 1 }
}

// MARK: - MasteryLevel Metrics

extension MasteryLevel {
    /// 进度值（0.0 - 1.0）
    nonisolated var progress: Double {
        Double(rawValue) / Double(Self.allCases.count - 1)
    }
    
    /// 复习优先级（越高越优先）
    ///
    /// 用于排序：掌握程度越低，优先级越高（越需要优先复习）
    /// - Note: 具体复习间隔由 `ReviewInterval` 计算，此属性仅用于相对排序
    nonisolated var reviewPriority: Int {
        Self.allCases.count - rawValue
    }
}

// MARK: - MasteryLevel Status Checks

extension MasteryLevel {
    /// 是否需要重点复习
    nonisolated var needsReview: Bool {
        self <= .partial
    }
    
    /// 是否已掌握
    nonisolated var isMastered: Bool {
        self >= .good
    }
    
    /// 是否完全掌握
    nonisolated var isFullyMastered: Bool {
        self == .mastered
    }
    
    /// 是否完全不会
    nonisolated var isUnknown: Bool {
        self == .none
    }
}

// MARK: - MasteryLevel Factory Methods

extension MasteryLevel {
    /// 从星级创建掌握程度（1-5）
    /// - Parameter stars: 星级数量
    /// - Returns: 对应的掌握程度，无效输入返回 nil
    static func from(stars: Int) -> MasteryLevel? {
        Self(rawValue: stars - 1)
    }
    
    /// 从进度值创建掌握程度（0.0-1.0）
    /// - Parameter progress: 进度值
    /// - Returns: 最接近的掌握程度
    static func from(progress: Double) -> MasteryLevel {
        let clamped = max(0, min(1, progress))
        let index = Int(round(clamped * Double(Self.allCases.count - 1)))
        return Self(rawValue: index) ?? .partial
    }
}

// MARK: - MasteryLevel Comparable

extension MasteryLevel: Comparable {
    nonisolated static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - MasteryLevel CustomStringConvertible

extension MasteryLevel: CustomStringConvertible {
    nonisolated var description: String { displayName }
}

// MARK: - MasteryLevel Collections

extension MasteryLevel {
    /// 需要复习的掌握程度
    static let reviewNeeded: [MasteryLevel] = [.none, .glimpse, .partial]
    
    /// 已掌握的程度
    static let masteredLevels: [MasteryLevel] = [.good, .mastered]
    
    /// 按复习优先级排序（优先复习的在前）
    static let sortedByReviewPriority: [MasteryLevel] = allCases.sorted { $0.reviewPriority > $1.reviewPriority }
}
