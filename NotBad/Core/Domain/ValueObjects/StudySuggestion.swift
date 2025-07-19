//
//  StudySuggestion.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  StudySuggestion.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainEntitiesLearningLearningState // 包含 LearningState

/// 学习建议值对象
/// 封装了根据题目学习状态生成的个性化学习建议。
/// 这是一个不可变的值对象，用于向学习者提供指导。
struct StudySuggestion: Codable, Sendable, Hashable {
    let message: String // 学习建议的主要信息
    let actionItems: [String] // 建议学习者采取的行动列表
    let estimatedTime: TimeInterval // 完成建议所需预估时间（秒）
    let difficulty: Difficulty // 建议所针对的题目难度
    let priority: StudyPriority // 学习建议的优先级

    /// 学习建议优先级枚举
    enum StudyPriority: String, Codable, Sendable {
        case low = "可选"    // 可选的建议
        case medium = "建议" // 建议采取的行动
        case high = "必要"   // 必须采取的行动
    }

    /// 初始化 StudySuggestion
    /// - Parameters:
    ///   - message: 建议消息
    ///   - actionItems: 行动项列表
    ///   - estimatedTime: 预估时间
    ///   - difficulty: 题目难度
    ///   - priority: 建议优先级
    init(
        message: String,
        actionItems: [String],
        estimatedTime: TimeInterval,
        difficulty: Difficulty,
        priority: StudyPriority
    ) {
        self.message = message
        self.actionItems = actionItems
        self.estimatedTime = estimatedTime
        self.difficulty = difficulty
        self.priority = priority
    }

    /// 静态工厂方法，根据题目的当前学习状态生成学习建议。
    /// 此方法应在 Question 聚合根内部或通过 Application 层调用。
    /// - Parameters:
    ///   - question: 题目聚合根实例
    ///   - learningState: 题目的当前学习状态
    ///   - difficulty: 题目的难度
    /// - Returns: 生成的 StudySuggestion 值对象
    static func generate(
        for question: Question, // 传入 Question 聚合根以获取其完整信息
        basedOn learningState: LearningState,
        difficulty: Difficulty
    ) -> StudySuggestion {
        let masteryLevel = learningState.masteryLevel
        let accuracy = learningState.accuracy
        let totalAttempts = learningState.totalAttempts

        switch (masteryLevel, accuracy, totalAttempts) {
        case (.unknown, _, 0):
            return StudySuggestion(
                message: "这是一道新题目，建议先仔细阅读题目内容",
                actionItems: ["仔细阅读题目", "分析题目类型", "尝试解答"],
                estimatedTime: 300, // 5分钟
                difficulty: difficulty,
                priority: .medium
            )

        case (.struggling, _, _):
            return StudySuggestion(
                message: "这道题目对你有些困难，建议重点学习相关知识点",
                actionItems: [
                    "复习相关概念和公式",
                    "查看详细解析",
                    "练习类似题目",
                    "寻求帮助或指导"
                ],
                estimatedTime: 900, // 15分钟
                difficulty: difficulty,
                priority: .high
            )

        case (.learning, let acc, _) where acc < 0.6:
            return StudySuggestion(
                message: "你在这道题目上有进步，但还需要更多练习",
                actionItems: [
                    "反复练习此题",
                    "总结解题步骤",
                    "练习变式题目"
                ],
                estimatedTime: 600, // 10分钟
                difficulty: difficulty,
                priority: .medium
            )

        case (.improving, _, _):
            return StudySuggestion(
                message: "你对这道题目掌握得不错，可以尝试更有挑战性的练习",
                actionItems: [
                    "定期复习巩固",
                    "尝试限时练习",
                    "学习多种解法"
                ],
                estimatedTime: 300, // 5分钟
                difficulty: difficulty,
                priority: .low
            )

        case (.mastered, _, _):
            return StudySuggestion(
                message: "你已经很好地掌握了这道题目",
                actionItems: [
                    "偶尔复习保持熟练度",
                    "帮助他人解答类似问题",
                    "探索相关高级话题"
                ],
                estimatedTime: 180, // 3分钟
                difficulty: difficulty,
                priority: .low
            )

        default:
            return StudySuggestion(
                message: "继续保持学习的积极性",
                actionItems: ["继续练习", "保持复习"],
                estimatedTime: 300,
                difficulty: difficulty,
                priority: .medium
            )
        }
    }
}
