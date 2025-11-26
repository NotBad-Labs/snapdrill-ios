//
//  ReviewItem+Display.swift
//  NotBad
//
//  显示属性扩展
//

import Foundation

// MARK: - ReviewItem Display Properties

extension ReviewItem {
    
    /// 显示标题
    ///
    /// 如果标题为空或仅空白，返回默认标题。
    var displayTitle: String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "未命名错题" : trimmed
    }
    
    /// 简短描述
    ///
    /// 格式：「学科 · 题型」
    var shortDescription: String {
        "\(subject.displayName) · \(questionType.displayName)"
    }
    
    /// 完整描述
    ///
    /// 格式：「学科 · 年级 · 题型 · 难度」
    var fullDescription: String {
        "\(subject.displayName) · \(grade.displayName) · \(questionType.displayName) · \(difficulty.displayName)"
    }
    
    /// 复习状态描述
    var reviewStatusDescription: String {
        if isNew {
            return "新录入，尚未复习"
        } else if needsReview {
            return isOverdue ? "已逾期 \(reviewInterval.overdueByDays) 天" : "今天需要复习"
        } else {
            return "\(daysUntilReview) 天后复习"
        }
    }
    
    /// 掌握状态描述
    var masteryStatusDescription: String {
        "\(mastery.displayName) · 已复习 \(reviewCount) 次"
    }
}

// MARK: - ReviewItem CustomStringConvertible

extension ReviewItem: CustomStringConvertible {
    
    /// 调试描述
    var description: String {
        "ReviewItem(\(displayTitle), \(shortDescription), \(masteryStatusDescription))"
    }
}
