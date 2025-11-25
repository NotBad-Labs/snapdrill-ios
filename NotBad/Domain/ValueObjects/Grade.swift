//
//  Grade.swift
//  NotBad
//
//  年级值对象 - K12教育（小学到高中）
//

import SwiftUI

/// 年级（K12：小学1-6年级 + 初中7-9年级 + 高中10-12年级）
enum Grade: String, CaseIterable, Codable {
    // 小学 (6年)
    case grade1 = "一年级"
    case grade2 = "二年级"
    case grade3 = "三年级"
    case grade4 = "四年级"
    case grade5 = "五年级"
    case grade6 = "六年级"
    // 初中 (3年)
    case grade7 = "七年级"
    case grade8 = "八年级"
    case grade9 = "九年级"
    // 高中 (3年)
    case grade10 = "高一"
    case grade11 = "高二"
    case grade12 = "高三"
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .grade1: return "小一"
        case .grade2: return "小二"
        case .grade3: return "小三"
        case .grade4: return "小四"
        case .grade5: return "小五"
        case .grade6: return "小六"
        case .grade7: return "初一"
        case .grade8: return "初二"
        case .grade9: return "初三"
        case .grade10: return "高一"
        case .grade11: return "高二"
        case .grade12: return "高三"
        }
    }
    
    /// 学段分组
    var stage: GradeStage {
        switch self {
        case .grade1, .grade2, .grade3, .grade4, .grade5, .grade6:
            return .primary
        case .grade7, .grade8, .grade9:
            return .junior
        case .grade10, .grade11, .grade12:
            return .senior
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .grade1, .grade2:
            return "figure.child"
        case .grade3, .grade4, .grade5, .grade6:
            return "figure.child.and.lock"
        case .grade7, .grade8, .grade9:
            return "figure.stand"
        case .grade10, .grade11, .grade12:
            return "graduationcap"
        }
    }
    
    /// 颜色（同学段渐变）
    var color: Color {
        switch self {
        // 小学：绿色系
        case .grade1: return .mint
        case .grade2: return .green
        case .grade3: return .teal
        case .grade4: return .cyan
        case .grade5: return .blue
        case .grade6: return .indigo
        // 初中：暖色系
        case .grade7: return .yellow
        case .grade8: return .orange
        case .grade9: return .red
        // 高中：紫色系
        case .grade10: return .pink
        case .grade11: return .purple
        case .grade12: return Color(red: 0.5, green: 0, blue: 0.5) // 深紫
        }
    }
    
    /// 年级序号（用于排序，1-12）
    var order: Int {
        switch self {
        case .grade1: return 1
        case .grade2: return 2
        case .grade3: return 3
        case .grade4: return 4
        case .grade5: return 5
        case .grade6: return 6
        case .grade7: return 7
        case .grade8: return 8
        case .grade9: return 9
        case .grade10: return 10
        case .grade11: return 11
        case .grade12: return 12
        }
    }
}

/// 学段
enum GradeStage: String, CaseIterable {
    case primary = "小学"
    case junior = "初中"
    case senior = "高中"
    
    var displayName: String { rawValue }
    
    /// 该学段包含的年级
    var grades: [Grade] {
        Grade.allCases.filter { $0.stage == self }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .primary: return "figure.child"
        case .junior: return "figure.stand"
        case .senior: return "graduationcap"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .primary: return .green
        case .junior: return .orange
        case .senior: return .purple
        }
    }
}
