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

    /// 重置复习进度（退阶策略）
    ///
    /// 采用温和的退阶策略而非直接清零，保护用户学习积极性：
    /// - 掌握度降级（而非归零）
    /// - 复习次数减半（而非清零）
    /// - 下次复习日期设为今天
    ///
    /// ## 退阶规则
    /// - mastered → partial（已掌握 → 部分掌握）
    /// - good → partial（良好 → 部分掌握）
    /// - partial → glimpse（部分掌握 → 初步了解）
    /// - glimpse/none → none（保持最低）
    ///
    /// ## 设计理由
    /// 对于 K12 学生，如果一道题复习了 10 次突然忘了一次，
    /// 直接重置回起点会严重打击积极性。退阶策略更符合学习心理学。
    func resetProgress() {
        // 退阶掌握度
        switch mastery {
        case .mastered, .good:
            mastery = .partial
        case .partial:
            mastery = .glimpse
        case .glimpse, .none:
            mastery = .none
        }
        
        // 复习次数减半（保留学习记录）
        reviewCount = max(0, reviewCount / 2)
        
        // 下次复习设为今天
        nextReviewDate = Date()
        markAsUpdated()
    }
    
    /// 完全重置复习进度（强制清零）
    ///
    /// 将复习次数完全清零，掌握程度重置为初始状态。
    /// 仅在用户明确要求"从头开始"时使用。
    func hardResetProgress() {
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
