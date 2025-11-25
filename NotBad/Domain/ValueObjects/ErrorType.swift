//
//  ErrorType.swift
//  NotBad
//
//  错误类型值对象 - 按错误根因分类
//

import SwiftUI

/// 错误类型分类
enum ErrorCategory: String, CaseIterable, Codable {
    case knowledge = "知识类"   // 概念不清、知识遗忘
    case method = "方法类"      // 方法不当、思路错误
    case habit = "习惯类"       // 计算错误、粗心大意、审题失误、步骤遗漏
    case objective = "客观类"   // 时间不足
    case other = "其他"
    
    var displayName: String { rawValue }
    
    /// 图标
    var icon: String {
        switch self {
        case .knowledge: return "brain"
        case .method: return "arrow.triangle.branch"
        case .habit: return "hand.raised"
        case .objective: return "clock"
        case .other: return "ellipsis.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .knowledge: return .purple
        case .method: return .red
        case .habit: return .orange
        case .objective: return .gray
        case .other: return .secondary
        }
    }
    
    /// 改进方向
    var improvementDirection: String {
        switch self {
        case .knowledge: return "加强学习理解"
        case .method: return "总结解题套路"
        case .habit: return "培养良好习惯"
        case .objective: return "提高做题效率"
        case .other: return "具体问题具体分析"
        }
    }
}

/// 错题错误类型
enum ErrorType: String, CaseIterable, Codable {
    // 知识类
    case concept = "概念不清"
    case forgotten = "知识遗忘"
    
    // 方法类
    case method = "方法不当"
    case wrongDirection = "思路错误"
    
    // 习惯类
    case calculation = "计算错误"
    case careless = "粗心大意"
    case misread = "审题失误"
    case incomplete = "步骤遗漏"
    
    // 客观类
    case timeLimit = "时间不足"
    
    // 其他
    case other = "其他"
    
    /// 显示名称
    var displayName: String { rawValue }
    
    /// 简短标签
    var shortLabel: String {
        switch self {
        case .concept: return "概念"
        case .forgotten: return "遗忘"
        case .method: return "方法"
        case .wrongDirection: return "思路"
        case .calculation: return "计算"
        case .careless: return "粗心"
        case .misread: return "审题"
        case .incomplete: return "遗漏"
        case .timeLimit: return "超时"
        case .other: return "其他"
        }
    }
    
    /// 错误分类
    var category: ErrorCategory {
        switch self {
        case .concept, .forgotten:
            return .knowledge
        case .method, .wrongDirection:
            return .method
        case .calculation, .careless, .misread, .incomplete:
            return .habit
        case .timeLimit:
            return .objective
        case .other:
            return .other
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .concept: return "lightbulb.slash"
        case .forgotten: return "brain.head.profile"
        case .method: return "arrow.triangle.branch"
        case .wrongDirection: return "arrow.uturn.backward"
        case .calculation: return "function"
        case .careless: return "exclamationmark.triangle"
        case .misread: return "eye.slash"
        case .incomplete: return "checklist.unchecked"
        case .timeLimit: return "clock.badge.exclamationmark"
        case .other: return "questionmark.circle"
        }
    }
    
    /// 颜色
    var color: Color {
        switch self {
        case .concept: return .purple
        case .forgotten: return .indigo
        case .method: return .red
        case .wrongDirection: return .pink
        case .calculation: return .blue
        case .careless: return .yellow
        case .misread: return .orange
        case .incomplete: return .mint
        case .timeLimit: return .gray
        case .other: return .secondary
        }
    }
    
    /// 改进建议
    var suggestion: String {
        switch self {
        case .concept: return "回顾基础概念，理解底层原理，建立知识体系"
        case .forgotten: return "定期复习，使用间隔重复法巩固记忆"
        case .method: return "总结解题方法，多看例题，归纳解题模板"
        case .wrongDirection: return "先分析题目考查点，再选择解题方向"
        case .calculation: return "加强计算练习，养成验算习惯，使用草稿纸"
        case .careless: return "做题时放慢速度，完成后检查一遍答案"
        case .misread: return "仔细读题，圈出关键词，标注已知条件"
        case .incomplete: return "列出完整解题步骤，逐步检查是否遗漏"
        case .timeLimit: return "提高解题速度，合理分配时间，先易后难"
        case .other: return "分析具体错误原因，针对性改进"
        }
    }
    
    /// 是否属于主观可控错误（可通过努力改进）
    var isControllable: Bool {
        category != .objective && self != .other
    }
    
    /// 严重程度（1-5，越高越需要重视）
    var severity: Int {
        switch self {
        case .concept, .method: return 5        // 根本性问题
        case .forgotten, .wrongDirection: return 4
        case .calculation, .misread: return 3
        case .careless, .incomplete: return 2
        case .timeLimit, .other: return 1       // 客观/不确定
        }
    }
}

// MARK: - 统计辅助

extension ErrorType {
    /// 获取某分类下的所有错误类型
    static func types(in category: ErrorCategory) -> [ErrorType] {
        allCases.filter { $0.category == category }
    }
}
