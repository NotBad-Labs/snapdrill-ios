//
//  QuestionStatistics.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  QuestionStatistics.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel

/// 题目统计信息值对象
/// 封装了题目在学习过程中的各项统计数据，用于报告、仪表盘或分析。
/// 这是一个不可变的值对象，纯粹用于数据展示和计算派生指标。
struct QuestionStatistics: Codable, Sendable, Hashable {
    let questionId: QuestionID // 题目的唯一标识符
    let totalAttempts: Int // 总答题尝试次数
    let correctAttempts: Int // 正确答题次数
    let accuracy: Double // 答题准确率 (0.0 - 1.0)
    let masteryLevel: MasteryLevel // 当前掌握程度
    let reviewCount: Int // 复习次数
    let lastReviewedAt: Date? // 上次复习时间
    let averageResponseTime: TimeInterval // 平均答题响应时间（秒）
    let createdAt: Date // 题目创建时间，用于统计分析

    /// 初始化 QuestionStatistics
    /// - Parameters:
    ///   - questionId: 题目ID
    ///   - totalAttempts: 总尝试次数
    ///   - correctAttempts: 正确尝试次数
    ///   - accuracy: 准确率
    ///   - masteryLevel: 掌握程度
    ///   - reviewCount: 复习次数
    ///   - lastReviewedAt: 上次复习时间
    ///   - averageResponseTime: 平均响应时间
    ///   - createdAt: 题目创建时间
    init(
        questionId: QuestionID,
        totalAttempts: Int,
        correctAttempts: Int,
        accuracy: Double,
        masteryLevel: MasteryLevel,
        reviewCount: Int,
        lastReviewedAt: Date?,
        averageResponseTime: TimeInterval,
        createdAt: Date // 确保从聚合根传入
    ) {
        self.questionId = questionId
        self.totalAttempts = totalAttempts
        self.correctAttempts = correctAttempts
        self.accuracy = accuracy
        self.masteryLevel = masteryLevel
        self.reviewCount = reviewCount
        self.lastReviewedAt = lastReviewedAt
        self.averageResponseTime = averageResponseTime
        self.createdAt = createdAt
    }

    /// 学习效率评分 (0-100)
    /// 这是一个派生属性，根据准确率、尝试次数和复习次数计算得分。
    var learningEfficiencyScore: Double {
        let accuracyScore = accuracy * 50 // 准确率对评分影响最大，最高50分
        let attemptsScore = min(25, Double(totalAttempts) * 2.5) // 尝试次数越多，得分越高，最高25分（10次尝试满分）
        let reviewScore = min(25, Double(reviewCount) * 5) // 复习次数越多，得分越高，最高25分（5次复习满分）

        return accuracyScore + attemptsScore + reviewScore
    }

    /// 判断题目是否为问题题目（需要特别关注，例如准确率低且尝试次数多）
    var isProblematic: Bool {
        return totalAttempts > 5 && accuracy < 0.5 && masteryLevel == .struggling
    }

    /// 判断题目是否为优势题目（已掌握且表现良好）
    var isStrength: Bool {
        return masteryLevel == .mastered && accuracy >= 0.9 && totalAttempts >= 3
    }
}
