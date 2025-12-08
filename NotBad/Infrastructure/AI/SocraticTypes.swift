//
//  SocraticTypes.swift
//  NotBad
//
//  苏格拉底式教学类型定义
//

import Foundation

// MARK: - Socratic Hint Level

/// 提示层级
///
/// 苏格拉底式教学采用渐进式提示，从最少提示逐步增加
enum SocraticHintLevel: Int, CaseIterable, Sendable {
    /// 第一层：方向性提示（只给思考方向）
    case direction = 1
    
    /// 第二层：概念提示（指出相关知识点）
    case concept = 2
    
    /// 第三层：步骤提示（分解解题步骤）
    case steps = 3
    
    /// 第四层：详细提示（给出关键思路）
    case detailed = 4
    
    /// 最终层：完整解答（实在不会时）
    case solution = 5
    
    /// 显示名称
    var displayName: String {
        switch self {
        case .direction:
            return "方向引导"
        case .concept:
            return "知识提示"
        case .steps:
            return "步骤分解"
        case .detailed:
            return "详细思路"
        case .solution:
            return "完整解答"
        }
    }
    
    /// 图标
    var icon: String {
        switch self {
        case .direction:
            return "arrow.right.circle"
        case .concept:
            return "lightbulb"
        case .steps:
            return "list.number"
        case .detailed:
            return "doc.text.magnifyingglass"
        case .solution:
            return "checkmark.circle"
        }
    }
    
    /// 下一个层级
    var next: SocraticHintLevel? {
        SocraticHintLevel(rawValue: rawValue + 1)
    }
}

// MARK: - Socratic Response

/// 苏格拉底式教学响应
struct SocraticResponse: Sendable {
    /// 提示层级
    let level: SocraticHintLevel
    
    /// 引导性问题（帮助学生思考）
    let guidingQuestions: [String]
    
    /// 提示内容
    let hint: String
    
    /// 鼓励语（激励学生继续思考）
    let encouragement: String
    
    /// 是否还有更多提示
    var hasMoreHints: Bool {
        level != .solution
    }
    
    /// 建议：如果还是不会怎么办
    var nextStepSuggestion: String {
        if let next = level.next {
            return "如果还是不太确定，可以点击「\(next.displayName)」获取更多帮助"
        }
        return "现在你应该能理解这道题了，试着自己再做一遍吧！"
    }
}

// MARK: - SocraticTeachingError

/// 苏格拉底教学错误
enum SocraticTeachingError: LocalizedError {
    /// 服务不可用
    case serviceUnavailable
    
    /// 分析超时
    case analysisTimeout
    
    /// 无效响应
    case invalidResponse
    
    /// Foundation Models 不可用
    case notAvailable
    
    /// 生成失败
    case generationFailed(String)
    
    /// 无效的题目内容
    case invalidContent
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable, .notAvailable:
            return String(localized: "socratic_error_unavailable", defaultValue: "AI 教学功能暂不可用")
        case .analysisTimeout:
            return String(localized: "socratic_error_timeout", defaultValue: "分析超时，请重试")
        case .invalidResponse, .invalidContent:
            return String(localized: "socratic_error_invalid", defaultValue: "题目内容无效")
        case .generationFailed(let reason):
            return String(localized: "socratic_error_generation_failed", defaultValue: "生成提示失败：\(reason)")
        }
    }
}
