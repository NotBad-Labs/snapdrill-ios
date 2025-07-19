//
//  ReviewPriority.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 复习优先级枚举
/// 代表一道题目在复习列表中的重要程度。
/// 这是一个值对象，用于清晰地表达复习策略的业务概念。
enum ReviewPriority: Int, Comparable, Codable, Sendable, Hashable {
    case low = 1    // 低优先级，可以稍后复习
    case medium = 2 // 中等优先级，建议在近期复习
    case high = 3   // 高优先级，需要立即复习

    /// 用于比较两个复习优先级的大小
    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// 用于UI展示的名称
    var displayName: String {
        switch self {
        case .low: return "低"
        case .medium: return "中"
        case .high: return "高"
        }
    }

    /// 用于UI展示的建议颜色（实际UI层会进行映射）
    var color: String {
        switch self {
        case .low: return "#34C759"    // 绿色
        case .medium: return "#FF9500" // 橙色
        case .high: return "#FF3B30"   // 红色
        }
    }
}
