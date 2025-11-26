//
//  ReviewItem+Actions.swift
//  NotBad
//
//  行为方法扩展
//

import Foundation

// MARK: - ReviewItem Actions

extension ReviewItem {
    
    /// 记录一次复习
    ///
    /// 更新掌握程度、复习次数和下次复习日期。
    ///
    /// - Parameter newMastery: 本次复习后的掌握程度
    func recordReview(newMastery: MasteryLevel) {
        mastery = newMastery
        reviewCount += 1
        
        // 计算下次复习日期
        let interval = ReviewInterval.calculate(
            reviewCount: reviewCount,
            mastery: newMastery
        )
        nextReviewDate = interval.nextReviewDate
        
        markAsUpdated()
    }
    
    /// 重置复习进度
    ///
    /// 将复习次数清零，掌握程度重置为初始状态。
    func resetProgress() {
        reviewCount = 0
        mastery = .none
        nextReviewDate = Date()
        markAsUpdated()
    }
    
    /// 添加知识点
    ///
    /// - Parameter point: 要添加的知识点
    func addKnowledgePoint(_ point: String) {
        var current = knowledgePoints
        current = current.adding(point)
        knowledgePoints = current
    }
    
    /// 移除知识点
    ///
    /// - Parameter point: 要移除的知识点
    func removeKnowledgePoint(_ point: String) {
        var current = knowledgePoints
        current = current.removing(point)
        knowledgePoints = current
    }
    
    /// 更新笔记
    ///
    /// - Parameter newNote: 新的笔记内容
    func updateNote(_ newNote: String) {
        note = newNote
        markAsUpdated()
    }
    
    /// 更新标题
    ///
    /// - Parameter newTitle: 新的标题
    func updateTitle(_ newTitle: String) {
        title = newTitle.isEmpty ? "未命名错题" : newTitle
        markAsUpdated()
    }
}

// MARK: - ReviewItem Validation

extension ReviewItem {
    
    /// 验证数据完整性
    ///
    /// - Returns: 验证结果和问题列表
    func validate() -> (isValid: Bool, issues: [String]) {
        var issues: [String] = []
        
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            issues.append("标题不能为空")
        }
        
        if imageData == nil && note.isEmpty {
            issues.append("建议添加图片或笔记")
        }
        
        if knowledgePoints.isEmpty {
            issues.append("建议添加知识点标签")
        }
        
        return (issues.isEmpty, issues)
    }
    
    /// 是否数据完整
    ///
    /// 要求：
    /// - 有图片或笔记（至少一项）
    /// - 有知识点标签
    /// - 标题非空
    var isComplete: Bool {
        (hasImage || hasNote) && hasKnowledgePoints && !title.isEmpty
    }
}

// MARK: - ReviewItem Comparable

extension ReviewItem: Comparable {
    
    /// 按紧迫程度排序
    ///
    /// 越需要复习的排在前面。
    static func < (lhs: ReviewItem, rhs: ReviewItem) -> Bool {
        lhs.nextReviewDate < rhs.nextReviewDate
    }
}
