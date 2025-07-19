//
//  Question.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (假设这些类型已在 Core/Domain 目录下各自的文件中定义)
// 例如:
// import NotBadCoreDomainEntitiesQuestionID // 如果 QuestionID 是一个独立的 Swift Package 或模块
// import NotBadCoreDomainEntitiesContent // 包含 Subject, Difficulty, Tag, QuestionContent, QuestionAttachment
// import NotBadCoreDomainEntitiesAnswer // 包含 Answer, AnswerCollection, AnswerResult
// import NotBadCoreDomainEntitiesLearning // 包含 LearningState, MasteryLevel, ReviewPriority, StudySuggestion, QuestionStatistics, LearningProgressAssessment
// import NotBadCoreDomainErrors // 包含 QuestionDomainError

// 为了编译通过和清晰性，这里假设它们在同一个模块内，因此只需要 Foundation。
// 在实际项目中，如果它们是独立的 Swift Package，您需要添加具体的 import 语句。

/// 题目聚合根
/// 代表学习系统中的一道题目及其完整的学习状态
///
/// 设计原则：
/// - 高内聚：题目数据、学习状态、复习逻辑作为一个完整概念
/// - 低耦合：不依赖外部框架，通过接口与外界交互
/// - 聚合根：维护内部一致性，是事务边界
struct Question: Equatable, Hashable, Identifiable, Sendable {

    // MARK: - 聚合根标识
    let id: QuestionID

    // MARK: - 核心业务数据（高内聚）
    // 这些属性是聚合的内部组成部分，通过私有访问控制维护聚合一致性
    private let content: QuestionContent
    private let answers: AnswerCollection
    private let metadata: QuestionMetadata
    private let learningState: LearningState

    // MARK: - 聚合根初始化
    /// 创建新题目（聚合根工厂方法）
    /// - Parameters:
    ///   - content: 题目内容
    ///   - answers: 答案集合
    ///   - metadata: 题目元数据
    /// - Throws: QuestionDomainError 如果数据无效
    init(
        id: QuestionID = QuestionID(),
        content: QuestionContent,
        answers: AnswerCollection,
        metadata: QuestionMetadata = QuestionMetadata()
    ) throws {
        // 聚合不变量验证：确保在创建时题目处于有效状态
        try Self.validateAggregateInvariants(
            content: content,
            answers: answers,
            metadata: metadata
        )

        self.id = id
        self.content = content
        self.answers = answers
        self.metadata = metadata
        self.learningState = LearningState() // 新题目的初始学习状态
    }

    /// 重建聚合（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用。
    /// 它不进行业务验证，因为假定从持久化存储中读取的数据是有效的。
    private init(
        id: QuestionID,
        content: QuestionContent,
        answers: AnswerCollection,
        metadata: QuestionMetadata,
        learningState: LearningState
    ) {
        self.id = id
        self.content = content
        self.answers = answers
        self.metadata = metadata
        self.learningState = learningState
    }
}

// MARK: - 聚合根核心业务行为（高内聚）
extension Question {

    /// 学习者答题（聚合根的核心用例）
    /// 此方法封装了答题逻辑和学习状态的更新，确保聚合内数据一致性。
    /// - Parameter userAnswer: 学习者的答案
    /// - Parameter responseTime: 答题响应时间 (秒)，可选，默认为0
    /// - Returns: 包含答题结果和更新后的聚合根的新元组
    /// - Throws: QuestionDomainError 如果当前状态不允许答题
    func answerQuestion(_ userAnswer: String, responseTime: TimeInterval = 0) throws -> (result: AnswerResult, updatedQuestion: Question) {
        // 验证当前状态是否允许答题，例如：已掌握的题目有每日答题限制
        try learningState.validateCanAnswer()

        // 检查答案的正确性，这是 AnswerCollection 的职责
        let answerResult = answers.check(userAnswer)

        // 更新学习状态，LearningState 是一个值对象，返回新的实例
        let updatedLearningState = learningState.recordAttempt(
            isCorrect: answerResult.isCorrect,
            difficulty: metadata.difficulty,
            timestamp: Date(),
            responseTime: responseTime
        )

        // 返回新的聚合根实例，体现不可变性
        let updatedQuestion = Question(
            id: id,
            content: content,
            answers: answers,
            metadata: metadata,
            learningState: updatedLearningState
        )

        return (answerResult, updatedQuestion)
    }

    /// 标记为已复习（学习流程的重要节点）
    /// 此方法更新题目的复习状态，通常在学习会话结束时调用。
    /// - Returns: 更新后的聚合根的新实例
    /// - Throws: QuestionDomainError 如果当前状态不允许标记为已复习（例如，从未尝试过的题目）
    func markAsReviewed() throws -> Question {
        let updatedLearningState = try learningState.markReviewed(at: Date())

        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: metadata,
            learningState: updatedLearningState
        )
    }

    /// 更新题目难度（内容管理功能）
    /// 此方法用于调整题目的难度级别。
    /// - Parameter newDifficulty: 新的难度级别
    /// - Returns: 更新后的聚合根的新实例
    /// - Throws: QuestionDomainError 如果难度变更违反业务规则（例如：已掌握的题目不能降低难度）
    func updateDifficulty(_ newDifficulty: Difficulty) throws -> Question {
        // 业务规则：已经掌握的题目不能随意降低难度，以防止数据被恶意篡改或误操作。
        if learningState.masteryLevel == .mastered && newDifficulty < metadata.difficulty {
            throw QuestionDomainError.cannotReduceDifficultyForMasteredQuestion
        }

        // metadata 是一个值对象，其 withDifficulty 方法返回新的实例
        let updatedMetadata = metadata.withDifficulty(newDifficulty)

        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: updatedMetadata,
            learningState: learningState
        )
    }

    /// 添加标签（内容分类功能）
    /// 此方法用于为题目添加分类标签。
    /// - Parameter tag: 要添加的标签值对象
    /// - Returns: 更新后的聚合根的新实例
    /// - Throws: QuestionDomainError 如果标签添加违反业务规则（例如：标签冲突）
    func addTag(_ tag: Tag) throws -> Question {
        // metadata.addTag 可能会抛出冲突错误，这里将其向上抛出
        let updatedMetadata = try metadata.addTag(tag)

        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: updatedMetadata,
            learningState: learningState
        )
    }

    /// 移除标签
    /// 此方法用于从题目中移除标签。
    /// - Parameter tag: 要移除的标签值对象
    /// - Returns: 更新后的聚合根的新实例
    func removeTag(_ tag: Tag) -> Question {
        // metadata.removeTag 返回新的实例，体现不可变性
        let updatedMetadata = metadata.removeTag(tag)

        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: updatedMetadata,
            learningState: learningState
        )
    }

    /// 更新错误原因（学习反思功能）
    /// 此方法用于记录学习者在答错题目后的反思或错误原因。
    /// - Parameter reason: 错误原因描述，nil 表示清除
    /// - Returns: 更新后的聚合根的新实例
    func updateWrongReason(_ reason: String?) -> Question {
        // learningState 是一个值对象，其 updateWrongReason 方法返回新的实例
        let updatedLearningState = learningState.updateWrongReason(reason)

        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: metadata,
            learningState: updatedLearningState
        )
    }
}

// MARK: - 聚合根查询接口（读取封装）
extension Question {

    /// 题目显示内容
    var displayContent: String { content.text }

    /// 题目难度级别
    var difficulty: Difficulty { metadata.difficulty }

    /// 所属学科
    var subject: Subject { metadata.subject }

    /// 标签集合
    var tags: Set<Tag> { metadata.tags }

    /// 当前掌握程度
    var masteryLevel: MasteryLevel { learningState.masteryLevel }

    /// 答题准确率
    var accuracy: Double { learningState.accuracy }

    /// 总练习次数
    var totalAttempts: Int { learningState.totalAttempts }

    /// 正确次数
    var correctAttempts: Int { learningState.correctAttempts }

    /// 是否为新题目（从未尝试过）
    var isNew: Bool { learningState.totalAttempts == 0 }

    /// 是否已掌握（达到特定掌握标准）
    var isMastered: Bool { learningState.masteryLevel == .mastered }

    /// 是否需要复习（基于复习策略和当前时间）
    var needsReview: Bool {
        learningState.needsReview(
            basedOn: metadata.difficulty,
            at: Date() // 使用当前时间进行判断
        )
    }

    /// 下次复习的建议时间
    var nextReviewDate: Date {
        learningState.calculateNextReviewDate(
            difficulty: metadata.difficulty
        )
    }

    /// 复习优先级
    var reviewPriority: ReviewPriority {
        learningState.calculateReviewPriority(
            difficulty: metadata.difficulty,
            createdAt: metadata.createdAt
        )
    }
}

// MARK: - 聚合根业务查询方法
extension Question {

    /// 检查题目是否包含特定标签
    /// - Parameter tag: 要检查的标签
    /// - Returns: 如果包含该标签则为 true，否则为 false
    func hasTag(_ tag: Tag) -> Bool {
        metadata.hasTag(tag)
    }

    /// 检查题目是否属于特定学科
    /// - Parameter subject: 要检查的学科
    /// - Returns: 如果属于该学科则为 true，否则为 false
    func belongsTo(_ subject: Subject) -> Bool {
        metadata.subject == subject
    }

    /// 获取个性化学习建议
    /// 此方法根据题目的当前学习状态生成学习建议。
    /// - Returns: 包含学习建议消息、行动项、预估时间等信息的 StudySuggestion 值对象
    func getStudySuggestion() -> StudySuggestion {
        return StudySuggestion.generate(
            for: self,
            basedOn: learningState,
            difficulty: metadata.difficulty
        )
    }

    /// 获取题目统计摘要
    /// 此方法返回题目的完整学习统计信息，用于报告或展示。
    /// - Returns: QuestionStatistics 值对象，包含答题次数、准确率、掌握程度等
    func getStatisticsSummary() -> QuestionStatistics {
        return QuestionStatistics(
            questionId: id,
            totalAttempts: learningState.totalAttempts,
            correctAttempts: learningState.correctAttempts,
            accuracy: learningState.accuracy,
            masteryLevel: learningState.masteryLevel,
            reviewCount: learningState.reviewCount,
            lastReviewedAt: learningState.lastReviewedAt,
            averageResponseTime: learningState.averageResponseTime,
            createdAt: metadata.createdAt // 从 metadata 获取创建时间
        )
    }

    /// 评估学习进度
    /// 此方法对学习者在特定题目上的学习进度进行评估。
    /// - Returns: LearningProgressAssessment 值对象，包含当前掌握级别、进度百分比、优势/劣势等
    func assessLearningProgress() -> LearningProgressAssessment {
        return LearningProgressAssessment(
            currentLevel: learningState.masteryLevel,
            progressPercentage: learningState.calculateProgressPercentage(),
            strengthAreas: learningState.identifyStrengths(),
            improvementAreas: learningState.identifyWeaknesses(),
            recommendations: getStudySuggestion().actionItems
        )
    }
}

// MARK: - 聚合根工厂方法（企业级创建模式）
extension Question {

    /// 创建一道简单的题目
    /// 此方法提供了一种便捷的方式来创建只包含一个正确答案的题目。
    /// - Parameters:
    ///   - content: 题目文本内容
    ///   - correctAnswer: 题目的正确答案文本
    ///   - subject: 所属学科，默认为数学
    ///   - difficulty: 难度级别，默认为中等
    /// - Returns: 新创建的 Question 聚合根实例
    /// - Throws: QuestionDomainError 如果提供的参数无效（例如空内容、空答案）
    static func createSimpleQuestion(
        content: String,
        correctAnswer: String,
        subject: Subject = .mathematics,
        difficulty: Difficulty = .medium
    ) throws -> Question {
        let questionContent = try QuestionContent(text: content)
        let answerCollection = try AnswerCollection(correctAnswers: [correctAnswer])
        let metadata = QuestionMetadata(subject: subject, difficulty: difficulty)

        return try Question(
            content: questionContent,
            answers: answerCollection,
            metadata: metadata
        )
    }

    /// 创建一道多选题
    /// 此方法用于创建包含多个选项（其中包含一个或多个正确答案）的多选题。
    /// - Parameters:
    ///   - content: 题目文本内容
    ///   - options: 选项列表，每个选项包含文本和是否为正确答案的布尔值
    ///   - subject: 所属学科，默认为数学
    ///   - difficulty: 难度级别，默认为中等
    /// - Returns: 新创建的 Question 聚合根实例
    /// - Throws: QuestionDomainError 如果提供的参数无效（例如空内容、无选项、无正确答案）
    static func createMultipleChoiceQuestion(
        content: String,
        options: [(text: String, isCorrect: Bool)],
        subject: Subject = .mathematics,
        difficulty: Difficulty = .medium
    ) throws -> Question {
        let questionContent = try QuestionContent(text: content)
        let answerCollection = try AnswerCollection(options: options)

        var metadata = QuestionMetadata(subject: subject, difficulty: difficulty)
        // 自动为多选题添加“考试类型”标签，这体现了业务规则
        metadata = try metadata.addTag(try Tag("选择题", type: .exam))

        return try Question(
            content: questionContent,
            answers: answerCollection,
            metadata: metadata
        )
    }

    /// 从外部数据重建聚合根
    /// 此方法专供仓储层使用，用于从持久化存储中加载数据并重建 Question 聚合根。
    /// 它不执行业务验证，因为假定从可靠来源加载的数据是有效的。
    /// - Parameters:
    ///   - id: 题目的唯一标识符
    ///   - content: 题目内容值对象
    ///   - answers: 答案集合值对象
    ///   - metadata: 题目元数据值对象
    ///   - learningState: 题目的学习状态值对象
    /// - Returns: 重建的 Question 聚合根实例
    static func reconstruct(
        id: QuestionID,
        content: QuestionContent,
        answers: AnswerCollection,
        metadata: QuestionMetadata,
        learningState: LearningState
    ) -> Question {
        return Question(
            id: id,
            content: content,
            answers: answers,
            metadata: metadata,
            learningState: learningState
        )
    }
}

// MARK: - 聚合不变量验证（企业级约束）
extension Question {

    /// 验证聚合不变量
    /// 此静态方法在聚合根初始化时被调用，强制执行核心业务规则，确保聚合的有效性。
    /// - Parameters:
    ///   - content: 题目内容
    ///   - answers: 答案集合
    ///   - metadata: 元数据
    /// - Throws: QuestionDomainError 如果不变量被违反
    private static func validateAggregateInvariants(
        content: QuestionContent,
        answers: AnswerCollection,
        metadata: QuestionMetadata
    ) throws {
        // 不变量1：题目内容不能为空
        if content.isEmpty {
            throw QuestionDomainError.emptyContent
        }

        // 不变量2：题目必须包含至少一个正确答案
        if !answers.hasCorrectAnswers {
            throw QuestionDomainError.noCorrectAnswers
        }

        // 不变量3：标签数量限制 (示例业务规则，可根据实际需求调整)
        if metadata.tags.count > 10 {
            throw QuestionDomainError.invalidStateForOperation("标签数量不能超过10个")
        }

        // 不变量4：学科与标签一致性 (示例业务规则，确保标签与学科逻辑兼容)
        try validateSubjectTagConsistency(metadata: metadata)
    }

    /// 验证学科与标签的一致性
    /// 确保与学科相关的标签与题目的学科属性相匹配。
    private static func validateSubjectTagConsistency(metadata: QuestionMetadata) throws {
        let subjectRelatedTags = metadata.tags.filter { tag in
            tag.type == .subject // 筛选出类型为学科的标签
        }

        for tag in subjectRelatedTags {
            if !tag.isCompatibleWith(subject: metadata.subject) {
                throw QuestionDomainError.inconsistentSubjectAndTags(
                    subject: metadata.subject,
                    tag: tag
                )
            }
        }
    }
}

// MARK: - 协议遵循 (Equatable, Hashable, Identifiable, Codable, Sendable)
extension Question: Codable {
    // Question的所有属性都已是Codable，所以Question也自动符合Codable
}

// Equatable 和 Hashable 协议的实现，基于 id 属性，确保唯一性
extension Question {
    static func == (lhs: Question, rhs: Question) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - Sample Data for Testing (用于测试和预览的示例数据)
extension Question {
    static func sample() -> Question {
        return try! Question.createSimpleQuestion(
            content: "计算 2 + 3 = ?",
            correctAnswer: "5",
            subject: .mathematics,
            difficulty: .easy
        )
    }

    static func sampleMultipleChoice() -> Question {
        return try! Question.createMultipleChoiceQuestion(
            content: "下列哪个城市是日本的首都？",
            options: [
                (text: "大阪", isCorrect: false),
                (text: "东京", isCorrect: true),
                (text: "京都", isCorrect: false),
                (text: "札幌", isCorrect: false)
            ],
            subject: .geography,
            difficulty: .medium
        )
    }

    static func sampleDifficult() -> Question {
        return try! Question.createSimpleQuestion(
            content: "请解释量子纠缠现象。",
            correctAnswer: "量子纠缠是一种量子力学现象，指两个或多个粒子之间存在的一种特殊关联，无论它们相隔多远，一个粒子的状态变化会瞬间影响到另一个粒子，这种关联性超出了经典物理学的范畴。",
            subject: .physics,
            difficulty: .hard
        )
    }
}

