//
//  QuestionQueryHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationQueries // 包含 GetQuestionByIdQuery 等
// import NotBadCoreApplicationHandlers // 包含 QueryHandler 协议
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainRepositories // 包含 QuestionAggregateRepository 协议
// import NotBadCoreDomainErrors // 包含 QuestionDomainError
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainEntitiesLearningStudySuggestion // 包含 StudySuggestion
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID

/// 题目聚合根 (仅为编译目的包含，实际应从 Question.swift 导入)
// Note: In a real project, this would be in its own file: Core/Domain/Entities/Question/Question.swift
// For brevity, only essential properties for handlers are included.
struct Question: Equatable, Hashable, Identifiable, Sendable {
    let id: QuestionID
    let content: QuestionContent
    let answers: AnswerCollection
    let metadata: QuestionMetadata
    let learningState: LearningState

    // Reconstruct method for repository use
    static func reconstruct(
        id: QuestionID,
        content: QuestionContent,
        answers: AnswerCollection,
        metadata: QuestionMetadata,
        learningState: LearningState
    ) -> Question {
        return Question(id: id, content: content, answers: answers, metadata: metadata, learningState: learningState)
    }

    // Example properties needed by handlers
    var difficulty: Difficulty { metadata.difficulty }
    var subject: Subject { metadata.subject }
    var masteryLevel: MasteryLevel { learningState.masteryLevel }
    var tags: Set<Tag> { metadata.tags }
    var createdAt: Date { metadata.createdAt }

    // Methods needed by handlers
    func getStatisticsSummary() -> QuestionStatistics {
        // Placeholder for actual implementation from Question entity
        return QuestionStatistics(
            questionId: id,
            totalAttempts: learningState.totalAttempts,
            correctAttempts: learningState.correctAttempts,
            accuracy: learningState.accuracy,
            masteryLevel: learningState.masteryLevel,
            reviewCount: learningState.reviewCount,
            lastReviewedAt: learningState.lastReviewedAt,
            averageResponseTime: learningState.averageResponseTime,
            createdAt: metadata.createdAt
        )
    }

    func getStudySuggestion() -> StudySuggestion {
        // Placeholder for actual implementation from Question entity
        return StudySuggestion.generate(for: self, basedOn: learningState, difficulty: metadata.difficulty)
    }

    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool {
        // Placeholder for actual implementation from Question entity
        return learningState.needsReview(basedOn: difficulty, at: currentDate)
    }
}

/// 强类型ID (仅为编译目的包含，实际应从 QuestionID.swift 导入)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 学科枚举 (仅为编译目的包含，实际应从 Subject.swift 导入)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case chemistry = "化学"
    case biology = "生物"
    case english = "英语"
    case chinese = "语文"
    case history = "历史"
    case geography = "地理"
    case politics = "政治"
    case computerScience = "计算机科学"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return Subject.allCases.first(where: { $0.rawValue == name }) }
}

/// 难度级别枚举 (仅为编译目的包含，实际应从 Difficulty.swift 导入)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    var displayName: String { rawValue }
    var coefficient: Double {
        switch self {
        case .easy: return 1.0
        case .medium: return 1.5
        case .hard: return 2.0
        }
    }
    func isHard() -> Bool { self == .hard }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool {
        switch (lhs, rhs) {
        case (.easy, .medium), (.easy, .hard), (.medium, .hard): return true
        default: return false
        }
    }
}

/// 标签值对象 (仅为编译目的包含，实际应从 Tag.swift 导入)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case topic, knowledgePoint, exam, subject, custom }
    init(_ value: String, type: TagType = .custom) throws { self.value = value; self.type = type }
    func conflicts(with other: Tag) -> Bool { return false } // Simplified for compilation
    func isCompatibleWith(subject: Subject) -> Bool { return true } // Simplified for compilation
}

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    // ... other cases for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        }
    }
    var errorDescription: String? { return description }
}

/// 题目附件值对象 (仅为编译目的包含，实际应从 QuestionAttachment.swift 导入)
struct QuestionAttachment: Codable, Sendable, Hashable {
    let id: UUID
    let type: AttachmentType
    let url: URL
    let description: String?
    enum AttachmentType: String, Codable, Sendable { case image, audio, video, document }
    init(id: UUID = UUID(), type: AttachmentType, url: URL, description: String? = nil) { self.id = id; self.type = type; self.description = description; self.url = url }
}

/// 题目内容值对象 (仅为编译目的包含，实际应从 QuestionContent.swift 导入)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    let attachments: [QuestionAttachment]
    init(text: String, attachments: [QuestionAttachment] = []) throws { self.text = text; self.attachments = attachments }
    var isEmpty: Bool { text.isEmpty }
    var hasAttachments: Bool { !attachments.isEmpty }
}

/// 单个答案值对象 (仅为编译目的包含，实际应从 Answer.swift 导入)
struct Answer: Codable, Sendable, Hashable {
    let text: String
    let isCorrect: Bool
    let explanation: String?
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws { self.text = text; self.isCorrect = isCorrect; self.explanation = explanation }
    func matches(_ userInput: String) -> Bool { return true } // Simplified for compilation
}

/// 答案集合值对象 (仅为编译目的包含，实际应从 AnswerCollection.swift 导入)
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer]
    init(correctAnswers: [String]) throws { self.answers = [] } // Simplified for compilation
    init(options: [(text: String, isCorrect: Bool)]) throws { self.answers = [] } // Simplified for compilation
    var hasCorrectAnswers: Bool { return true } // Simplified for compilation
    var correctAnswers: [Answer] { return [] } // Simplified for compilation
    var allAnswers: [Answer] { return [] } // Simplified for compilation
    func check(_ userAnswer: String) -> AnswerResult { return AnswerResult(userAnswer: "", isCorrect: true, correctAnswers: []) } // Simplified for compilation
}

/// 题目元数据值对象 (仅为编译目的包含，实际应从 QuestionMetadata.swift 导入)
struct QuestionMetadata: Codable, Sendable, Hashable {
    let subject: Subject
    let difficulty: Difficulty
    let tags: Set<Tag>
    let source: String?
    let createdAt: Date
    let explanation: String?
    init(subject: Subject = .mathematics, difficulty: Difficulty = .medium, tags: Set<Tag> = [], source: String? = nil, createdAt: Date = Date(), explanation: String? = nil) {
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.source = source
        self.createdAt = createdAt
        self.explanation = explanation
    }
    func withDifficulty(_ newDifficulty: Difficulty) -> QuestionMetadata { return self } // Simplified for compilation
    func addTag(_ tag: Tag) throws -> QuestionMetadata { return self } // Simplified for compilation
    func removeTag(_ tag: Tag) -> QuestionMetadata { return self } // Simplified for compilation
    func hasTag(_ tag: Tag) -> Bool { return false } // Simplified for compilation
}

/// 掌握程度枚举 (仅为编译目的包含，实际应从 MasteryLevel.swift 导入)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 } // Simplified for compilation
}

/// 复习优先级枚举 (仅为编译目的包含，实际应从 ReviewPriority.swift 导入)
enum ReviewPriority: Int, Comparable, Codable, Sendable, Hashable {
    case low, medium, high
    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool { lhs.rawValue < rhs.rawValue }
    var displayName: String { rawValue }
    var color: String { "" } // Simplified for compilation
}

/// 学习状态值对象 (仅为编译目的包含，实际应从 LearningState.swift 导入)
struct LearningState: Codable, Sendable, Hashable {
    let totalAttempts: Int
    let correctAttempts: Int
    let reviewCount: Int
    let lastReviewedAt: Date?
    let lastAttemptAt: Date?
    let wrongReason: String?
    let responseTimeHistory: [TimeInterval]
    let masteryLevel: MasteryLevel
    private let dailyAttempts: [Date: Int]
    init(totalAttempts: Int = 0, correctAttempts: Int = 0, reviewCount: Int = 0, lastReviewedAt: Date? = nil, lastAttemptAt: Date? = nil, wrongReason: String? = nil, responseTimeHistory: [TimeInterval] = [], masteryLevel: MasteryLevel = .unknown, dailyAttempts: [Date: Int] = [:]) {
        self.totalAttempts = totalAttempts; self.correctAttempts = correctAttempts; self.reviewCount = reviewCount; self.lastReviewedAt = lastReviewedAt; self.lastAttemptAt = lastAttemptAt; self.wrongReason = wrongReason; self.responseTimeHistory = responseTimeHistory; self.masteryLevel = masteryLevel; self.dailyAttempts = dailyAttempts
    }
    var accuracy: Double { 0.0 } // Simplified for compilation
    var averageResponseTime: TimeInterval { 0.0 } // Simplified for compilation
    func recordAttempt(isCorrect: Bool, difficulty: Difficulty, timestamp: Date, responseTime: TimeInterval = 0) -> LearningState { return self } // Simplified for compilation
    func markReviewed(at date: Date) throws -> LearningState { return self } // Simplified for compilation
    func updateWrongReason(_ reason: String?) -> LearningState { return self } // Simplified for compilation
    func validateCanAnswer() throws { } // Simplified for compilation
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false } // Simplified for compilation
    func calculateNextReviewDate(difficulty: Difficulty) -> Date { return Date() } // Simplified for compilation
    func calculateReviewPriority(difficulty: Difficulty, createdAt: Date) -> ReviewPriority { return .low } // Simplified for compilation
    func calculateProgressPercentage() -> Double { return 0.0 } // Simplified for compilation
    func identifyStrengths() -> [String] { return [] } // Simplified for compilation
    func identifyWeaknesses() -> [String] { return [] } // Simplified for compilation
}

/// 答题结果值对象 (仅为编译目的包含，实际应从 AnswerResult.swift 导入)
struct AnswerResult: Codable, Sendable, Hashable {
    let userAnswer: String
    let isCorrect: Bool
    let correctAnswers: [String]
    let explanation: String?
    let timestamp: Date
    init(userAnswer: String, isCorrect: Bool, correctAnswers: [String], explanation: String? = nil) {
        self.userAnswer = userAnswer; self.isCorrect = isCorrect; self.correctAnswers = correctAnswers; self.explanation = explanation; self.timestamp = Date()
    }
}

/// 学习建议值对象 (仅为编译目的包含，实际应从 StudySuggestion.swift 导入)
struct StudySuggestion: Codable, Sendable, Hashable {
    let message: String
    let actionItems: [String]
    let estimatedTime: TimeInterval
    let difficulty: Difficulty
    let priority: StudyPriority
    enum StudyPriority: String, Codable, Sendable { case low, medium, high }
    init(message: String, actionItems: [String], estimatedTime: TimeInterval, difficulty: Difficulty, priority: StudyPriority) {
        self.message = message; self.actionItems = actionItems; self.estimatedTime = estimatedTime; self.difficulty = difficulty; self.priority = priority
    }
    static func generate(for question: Question, basedOn learningState: LearningState, difficulty: Difficulty) -> StudySuggestion {
        return StudySuggestion(message: "", actionItems: [], estimatedTime: 0, difficulty: difficulty, priority: .low)
    } // Simplified for compilation
}

/// 题目统计信息值对象 (仅为编译目的包含，实际应从 QuestionStatistics.swift 导入)
struct QuestionStatistics: Codable, Sendable, Hashable {
    let questionId: QuestionID
    let totalAttempts: Int
    let correctAttempts: Int
    let accuracy: Double
    let masteryLevel: MasteryLevel
    let reviewCount: Int
    let lastReviewedAt: Date?
    let averageResponseTime: TimeInterval
    let createdAt: Date
    init(questionId: QuestionID, totalAttempts: Int, correctAttempts: Int, accuracy: Double, masteryLevel: MasteryLevel, reviewCount: Int, lastReviewedAt: Date?, averageResponseTime: TimeInterval, createdAt: Date) {
        self.questionId = questionId; self.totalAttempts = totalAttempts; self.correctAttempts = correctAttempts; self.accuracy = accuracy; self.masteryLevel = masteryLevel; self.reviewCount = reviewCount; self.lastReviewedAt = lastReviewedAt; self.averageResponseTime = averageResponseTime; self.createdAt = createdAt
    }
    var learningEfficiencyScore: Double { 0.0 } // Simplified for compilation
    var isProblematic: Bool { false } // Simplified for compilation
    var isStrength: Bool { false } // Simplified for compilation
}

/// 学习进度评估结果值对象 (仅为编译目的包含，实际应从 LearningProgressAssessment.swift 导入)
struct LearningProgressAssessment: Codable, Sendable, Hashable {
    let currentLevel: MasteryLevel
    let progressPercentage: Double
    let strengthAreas: [String]
    let improvementAreas: [String]
    let recommendations: [String]
    init(currentLevel: MasteryLevel, progressPercentage: Double, strengthAreas: [String], improvementAreas: [String], recommendations: [String]) {
        self.currentLevel = currentLevel; self.progressPercentage = progressPercentage; self.strengthAreas = strengthAreas; self.improvementAreas = improvementAreas; self.recommendations = recommendations
    }
}


/// 题目聚合仓储接口 (仅为编译目的包含，实际应从 QuestionAggregateRepository.swift 导入)
protocol QuestionAggregateRepository: Sendable {
    func save(_ question: Question) async throws
    func find(by id: QuestionID) async throws -> Question?
    func findAll() async throws -> [Question]
    func find(by subject: Subject) async throws -> [Question]
    func find(by masteryLevel: MasteryLevel) async throws -> [Question]
    func findQuestionsNeedingReview() async throws -> [Question]
    func delete(_ question: Question) async throws
}


/// 获取题目命令处理器
/// 负责处理 `GetQuestionByIdQuery`，从仓储中获取单个题目。
struct GetQuestionByIdQueryHandler: QueryHandler {
    typealias Q = GetQuestionByIdQuery
    typealias R = Question? // 返回可选的 Question 聚合根

    private let questionRepository: QuestionAggregateRepository // 依赖注入仓储

    /// 初始化查询处理器
    /// - Parameter questionRepository: 题目聚合仓储的实例。
    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    /// 处理 `GetQuestionByIdQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `Question` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetQuestionByIdQuery) async throws -> Question? {
        return try await questionRepository.find(by: query.questionId)
    }
}

/// 获取所有题目查询处理器
/// 负责处理 `GetAllQuestionsQuery`，从仓储中获取所有题目。
struct GetAllQuestionsQueryHandler: QueryHandler {
    typealias Q = GetAllQuestionsQuery
    typealias R = [Question] // 返回 Question 聚合根数组

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetAllQuestionsQuery) async throws -> [Question] {
        return try await questionRepository.findAll()
    }
}

/// 根据学科获取题目列表查询处理器
/// 负责处理 `GetQuestionsBySubjectQuery`，根据指定学科获取题目。
struct GetQuestionsBySubjectQueryHandler: QueryHandler {
    typealias Q = GetQuestionsBySubjectQuery
    typealias R = [Question]

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetQuestionsBySubjectQuery) async throws -> [Question] {
        return try await questionRepository.find(by: query.subject)
    }
}

/// 根据难度获取题目列表查询处理器
/// 负责处理 `GetQuestionsByDifficultyQuery`，根据指定难度获取题目。
struct GetQuestionsByDifficultyQueryHandler: QueryHandler {
    typealias Q = GetQuestionsByDifficultyQuery
    typealias R = [Question]

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetQuestionsByDifficultyQuery) async throws -> [Question] {
        return try await questionRepository.find(by: query.difficulty)
    }
}

/// 根据掌握程度获取题目列表查询处理器
/// 负责处理 `GetQuestionsByMasteryLevelQuery`，根据指定掌握程度获取题目。
struct GetQuestionsByMasteryLevelQueryHandler: QueryHandler {
    typealias Q = GetQuestionsByMasteryLevelQuery
    typealias R = [Question]

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetQuestionsByMasteryLevelQuery) async throws -> [Question] {
        return try await questionRepository.find(by: query.masteryLevel)
    }
}

/// 获取需要复习的题目列表查询处理器
/// 负责处理 `GetQuestionsNeedingReviewQuery`，获取所有需要复习的题目。
struct GetQuestionsNeedingReviewQueryHandler: QueryHandler {
    typealias Q = GetQuestionsNeedingReviewQuery
    typealias R = [Question]

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetQuestionsNeedingReviewQuery) async throws -> [Question] {
        return try await questionRepository.findQuestionsNeedingReview()
    }
}

/// 搜索题目查询处理器
/// 负责处理 `SearchQuestionsQuery`，根据搜索条件筛选题目。
struct SearchQuestionsQueryHandler: QueryHandler {
    typealias Q = SearchQuestionsQuery
    typealias R = [Question]

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: SearchQuestionsQuery) async throws -> [Question] {
        // 1. 获取所有题目或根据初步条件筛选
        var questions = try await questionRepository.findAll()

        // 2. 应用搜索词过滤
        if !query.searchTerm.isEmpty {
            let lowercasedSearchTerm = query.searchTerm.lowercased()
            questions = questions.filter { question in
                question.content.text.lowercased().contains(lowercasedSearchTerm) ||
                question.metadata.source?.lowercased().contains(lowercasedSearchTerm) ?? false ||
                question.metadata.tags.contains(where: { $0.value.lowercased().contains(lowercasedSearchTerm) })
            }
        }

        // 3. 应用学科过滤
        if let subject = query.subject {
            questions = questions.filter { $0.subject == subject }
        }

        // 4. 应用难度过滤
        if let difficulty = query.difficulty {
            questions = questions.filter { $0.difficulty == difficulty }
        }

        // 5. 应用标签过滤
        if let tags = query.tags, !tags.isEmpty {
            questions = questions.filter { question in
                tags.isSubset(of: question.tags) // 题目包含所有指定的标签
            }
        }

        return questions
    }
}

/// 获取题目统计摘要查询处理器
/// 负责处理 `GetQuestionStatisticsQuery`，返回单个题目的统计信息。
struct GetQuestionStatisticsQueryHandler: QueryHandler {
    typealias Q = GetQuestionStatisticsQuery
    typealias R = QuestionStatistics // 返回 QuestionStatistics 值对象

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetQuestionStatisticsQuery) async throws -> QuestionStatistics {
        // 1. 通过仓储获取题目聚合根
        guard let question = try await questionRepository.find(by: query.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(query.questionId.rawValue) 未找到，无法获取统计信息。")
        }

        // 2. 调用聚合根的业务方法获取统计摘要
        return question.getStatisticsSummary()
    }
}

/// 获取学习建议查询处理器
/// 负责处理 `GetStudySuggestionQuery`，返回单个题目的学习建议。
struct GetStudySuggestionQueryHandler: QueryHandler {
    typealias Q = GetStudySuggestionQuery
    typealias R = StudySuggestion // 返回 StudySuggestion 值对象

    private let questionRepository: QuestionAggregateRepository

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    func handle(_ query: GetStudySuggestionQuery) async throws -> StudySuggestion {
        // 1. 通过仓储获取题目聚合根
        guard let question = try await questionRepository.find(by: query.questionId) else {
            throw QuestionDomainError.invalidStateForOperation("题目ID \(query.questionId.rawValue) 未找到，无法获取学习建议。")
        }

        // 2. 调用聚合根的业务方法获取学习建议
        return question.getStudySuggestion()
    }
}

