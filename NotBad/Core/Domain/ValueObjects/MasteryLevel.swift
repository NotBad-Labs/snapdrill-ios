//
//  MasteryLevel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  MasteryLevel.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 掌握程度枚举
/// 代表学习者对一道题目的掌握程度。
/// 这是一个值对象，用于清晰地表达学习状态的业务概念。
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown = "未知" // 尚未尝试或尚未评估
    case struggling = "困难" // 准确率低，需要大量练习
    case learning = "学习中" // 正在进步，但尚未完全掌握
    case improving = "进步中" // 准确率较高，接近掌握
    case mastered = "已掌握" // 准确率高，可以减少练习频率

    /// 用于UI展示的名称
    var displayName: String { rawValue }

    /// 对应掌握程度的进度值 (0.0 - 1.0)，用于计算整体学习进度百分比
    var progressValue: Double {
        switch self {
        case .unknown: return 0.0
        case .struggling: return 0.2
        case .learning: return 0.4
        case .improving: return 0.7
        case .mastered: return 1.0
        }
    }
}
