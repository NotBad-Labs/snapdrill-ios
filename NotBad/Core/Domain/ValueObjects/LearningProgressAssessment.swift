//
//  LearningProgressAssessment.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  LearningProgressAssessment.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel

/// 学习进度评估结果值对象
/// 封装了对学习者在特定题目上的学习进度进行的评估结果。
/// 这是一个不可变的值对象，用于提供结构化的学习反馈。
struct LearningProgressAssessment: Codable, Sendable, Hashable {
    let currentLevel: MasteryLevel // 当前掌握程度
    let progressPercentage: Double // 学习进度百分比 (0.0 - 100.0)
    let strengthAreas: [String] // 学习优势领域列表
    let improvementAreas: [String] // 学习待改进领域列表
    let recommendations: [String] // 基于评估结果的行动建议列表

    /// 初始化 LearningProgressAssessment
    /// - Parameters:
    ///   - currentLevel: 当前掌握程度
    ///   - progressPercentage: 进度百分比
    ///   - strengthAreas: 优势领域
    ///   - improvementAreas: 待改进领域
    ///   - recommendations: 推荐行动
    init(
        currentLevel: MasteryLevel,
        progressPercentage: Double,
        strengthAreas: [String],
        improvementAreas: [String],
        recommendations: [String]
    ) {
        self.currentLevel = currentLevel
        self.progressPercentage = progressPercentage
        self.strengthAreas = strengthAreas
        self.improvementAreas = improvementAreas
        self.recommendations = recommendations
    }
}
