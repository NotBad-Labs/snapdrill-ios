//
//  Difficulty.swift
//  NotBad
//
//  题目难度值对象 - 5级制
//

import SwiftUI

/// 题目难度等级（5级制）
enum Difficulty: Int, CaseIterable, Codable {
    case basic = 0     // 送分题
    case easy = 1      // 简单
    case medium = 2    // 中等
    case hard = 3      // 困难
    case extreme = 4   // 压轴
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .basic: return "送分"
        case .easy: return "简单"
        case .medium: return "中等"
        case .hard: return "困难"
        case .extreme: return "压轴"
        }
    }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .basic: return "送"
        case .easy: return "易"
        case .medium: return "中"
        case .hard: return "难"
        case .extreme: return "压"
        }
    }
    
    /// 详细描述
    var detailText: String {
        switch self {
        case .basic: return "基础概念直接应用，几乎不会出错"
        case .easy: return "常规题型，稍加思考即可解决"
        case .medium: return "需要一定分析，容易粗心出错"
        case .hard: return "综合性强，需要灵活运用多个知识点"
        case .extreme: return "压轴难度，极具挑战性"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .basic: return "gift"
        case .easy: return "star"
        case .medium: return "star.leadinghalf.filled"
        case .hard: return "star.fill"
        case .extreme: return "flame.fill"
        }
    }
    
    /// 颜色（绿→蓝→黄→橙→红 渐进）
    var color: Color {
        switch self {
        case .basic: return .mint
        case .easy: return .green
        case .medium: return .yellow
        case .hard: return .orange
        case .extreme: return .red
        }
    }
    
    /// 星级（1-5）
    var stars: Int { rawValue + 1 }
    
    /// 难度系数（0.0-1.0）
    var coefficient: Double {
        Double(rawValue) / Double(Self.allCases.count - 1)
    }
    
    /// 建议复习优先级（1-5，数字越大优先级越高）
    var reviewPriority: Int {
        rawValue + 1
    }
    
    /// 预计耗时倍数（相对于基准时间）
    var timeMultiplier: Double {
        switch self {
        case .basic: return 0.5
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        case .extreme: return 3.0
        }
    }
}

// MARK: - Comparable

extension Difficulty: Comparable {
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
