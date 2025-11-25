//
//  MasteryLevel.swift
//  NotBad
//
//  掌握程度值对象 - 5级制
//

import SwiftUI

/// 错题掌握程度（5级制，类似5星评分）
enum MasteryLevel: Int, CaseIterable, Codable {
    case none = 0       // ⭐ 完全不会
    case glimpse = 1    // ⭐⭐ 一知半解
    case partial = 2    // ⭐⭐⭐ 似懂非懂
    case good = 3       // ⭐⭐⭐⭐ 基本掌握
    case mastered = 4   // ⭐⭐⭐⭐⭐ 完全掌握
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .none: return "不会"
        case .glimpse: return "一知半解"
        case .partial: return "似懂非懂"
        case .good: return "基本掌握"
        case .mastered: return "完全掌握"
        }
    }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .none: return "不会"
        case .glimpse: return "半解"
        case .partial: return "似懂"
        case .good: return "掌握"
        case .mastered: return "精通"
        }
    }
    
    /// 详细描述
    var detailText: String {
        switch self {
        case .none: return "完全不会，需要重新学习基础概念"
        case .glimpse: return "看答案后能懂，但自己做不出来"
        case .partial: return "能做对但不确定，解题思路不清晰"
        case .good: return "能独立完成，偶尔会粗心出错"
        case .mastered: return "完全掌握，能举一反三解决变式题"
        }
    }
    
    /// 星级（1-5）
    var stars: Int { rawValue + 1 }
    
    /// 进度值（0.0 - 1.0）
    var progress: Double {
        Double(rawValue) / Double(Self.allCases.count - 1)
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .none: return "xmark.circle.fill"
        case .glimpse: return "eye.fill"
        case .partial: return "questionmark.circle.fill"
        case .good: return "checkmark.circle.fill"
        case .mastered: return "star.circle.fill"
        }
    }
    
    /// 颜色（红→橙→黄→薄荷→绿 渐进）
    var color: Color {
        switch self {
        case .none: return .red
        case .glimpse: return .orange
        case .partial: return .yellow
        case .good: return .mint
        case .mastered: return .green
        }
    }
    
    /// 下次复习间隔天数（基于艾宾浩斯遗忘曲线）
    var reviewIntervalDays: Int {
        switch self {
        case .none: return 0      // 立即复习
        case .glimpse: return 1   // 1天后
        case .partial: return 3   // 3天后
        case .good: return 7      // 7天后
        case .mastered: return 14 // 14天后
        }
    }
    
    /// 复习优先级（越低越优先）
    var reviewPriority: Int {
        Self.allCases.count - rawValue
    }
    
    /// 是否需要重点复习
    var needsReview: Bool {
        self <= .partial
    }
    
    /// 是否已掌握
    var isMastered: Bool {
        self >= .good
    }
}

// MARK: - Comparable

extension MasteryLevel: Comparable {
    static func < (lhs: MasteryLevel, rhs: MasteryLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
