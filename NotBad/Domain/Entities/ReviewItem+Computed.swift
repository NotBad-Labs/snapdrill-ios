//
//  ReviewItem+Computed.swift
//  NotBad
//
//  计算属性扩展
//

import Foundation

// MARK: - ReviewItem Computed Properties

extension ReviewItem {
    
    /// 复习间隔计算器
    ///
    /// 基于当前复习次数和掌握程度计算。
    var reviewInterval: ReviewInterval {
        ReviewInterval.calculate(reviewCount: reviewCount, mastery: mastery)
    }
    
    /// 是否有图片
    var hasImage: Bool {
        imageData != nil && !(imageData?.isEmpty ?? true)
    }
    
    /// 是否有笔记
    var hasNote: Bool {
        !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// 是否有知识点
    var hasKnowledgePoints: Bool {
        !knowledgePoints.isEmpty
    }
    
    /// 是否需要复习
    ///
    /// 基于下次复习日期判断。
    var needsReview: Bool {
        nextReviewDate <= Date()
    }
    
    /// 是否已逾期
    ///
    /// 直接基于 `nextReviewDate` 判断，避免重新计算间隔导致不一致。
    var isOverdue: Bool {
        nextReviewDate < Calendar.current.startOfDay(for: Date())
    }
    
    /// 是否已掌握
    ///
    /// 掌握程度达到 `.good` 或以上。
    var isMastered: Bool {
        mastery.isMastered
    }
    
    /// 是否为新录入（从未复习）
    var isNew: Bool {
        reviewCount == 0
    }
    
    /// 距离下次复习的天数
    var daysUntilReview: Int {
        reviewInterval.daysUntilReview
    }
    
    /// 估算记忆保持率
    var estimatedRetention: Double {
        reviewInterval.estimatedRetention
    }
    
    /// 复习紧迫程度（1-5）
    var urgencyLevel: Int {
        reviewInterval.urgencyLevel
    }
    
    /// 创建至今的天数
    var daysSinceCreation: Int {
        Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
    }
    
    /// 综合难度分数
    ///
    /// 结合题型权重和难度等级计算。
    var overallDifficultyScore: Double {
        Double(difficulty.rawValue) * questionType.difficultyWeight
    }
}
