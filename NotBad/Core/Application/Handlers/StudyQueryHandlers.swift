//
//  StudyQueryHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationQueries // 包含 GetStudySessionByIdQuery 等
// import NotBadCoreApplicationHandlers // 包含 QueryHandler 协议
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession (实体)
// import NotBadCoreDomainEntitiesStudyStudyProgress // 包含 StudyProgress (实体)
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainRepositories // 包含 StudySessionAggregateRepository, StudyProgressRepository, StudyPlanRepository
// import NotBadCoreDomainErrors // 包含 UserDomainError (或其他通用领域错误)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 题目ID强类型 (仅为编译目的包含，实际应从 QuestionID.swift 导入)
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

/// 主题领域实体 (仅为编译目的包含，实际应从 Topic.swift 导入)
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    init(id: UUID = UUID(), name: String, subject: Subject) { self.id = id; self.name = name; self.subject = subject }
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return try! Topic(id: id, name: name, subject: subject) // Simplified for compilation
    }
}

/// 学习会话中的题目尝试记录 (仅为编译目的包含，实际应从 StudySession.swift 导入)
struct StudySessionQuestionAttempt: Codable, Hashable, Sendable {
    let questionId: QuestionID
    let userAnswer: String
    let isCorrect: Bool
    let responseTime: TimeInterval
    let timestamp: Date
    init(questionId: QuestionID, userAnswer: String, isCorrect: Bool, responseTime: TimeInterval, timestamp: Date = Date()) {
        self.questionId = questionId; self.userAnswer = userAnswer; self.isCorrect = isCorrect; self.responseTime = responseTime; self.timestamp = timestamp
    }
}

/// 学习会话领域实体 (仅为编译目的包含，实际应从 StudySession.swift 导入)
struct StudySession: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let startTime: Date
    let endTime: Date?
    let subject: Subject?
    let sessionType: String
    let questionIds: Set<QuestionID>
    let answeredQuestions: [QuestionID: StudySessionQuestionAttempt]
    let isCompleted: Bool

    init(id: UUID = UUID(), userId: UserID, startTime: Date = Date(), endTime: Date? = nil, subject: Subject? = nil, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt] = [:], isCompleted: Bool = false) {
        guard !questionIds.isEmpty else { fatalError("StudySession must contain at least one question ID.") }
        self.id = id; self.userId = userId; self.startTime = startTime; self.endTime = endTime; self.subject = subject; self.sessionType = sessionType; self.questionIds = questionIds; self.answeredQuestions = answeredQuestions; self.isCompleted = isCompleted
    }
    static func reconstruct(id: UUID, userId: UserID, startTime: Date, endTime: Date?, subject: Subject?, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt], isCompleted: Bool) -> StudySession {
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: answeredQuestions, isCompleted: isCompleted)
    }
    func recordQuestionAttempt(questionId: QuestionID, userAnswer: String, isCorrect: Bool, responseTime: TimeInterval) throws -> StudySession { return self }
    func endSession(at endTime: Date, isCompleted: Bool) throws -> StudySession { return self }
    var duration: TimeInterval { 0.0 }
    var answeredQuestionCount: Int { 0 }
    var correctQuestionCount: Int { 0 }
    var sessionAccuracy: Double { 0.0 }
    var averageResponseTime: TimeInterval { 0.0 }
    var allQuestionIDs: [QuestionID] { [] }
    var allAnsweredAttempts: [StudySessionQuestionAttempt] { [] }
}

/// 学习计划领域实体 (仅为编译目的包含，实际应从 StudyPlan.swift 导入)
struct StudyPlan: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let details: String
    let targetSubjects: Set<Subject>
    let dailyStudyGoalMinutes: Int
    let createdAt: Date
    let lastModifiedAt: Date
    init(id: UUID = UUID(), userId: UserID, details: String, targetSubjects: Set<Subject>, dailyStudyGoalMinutes: Int, createdAt: Date = Date(), lastModifiedAt: Date = Date()) {
        self.id = id; self.userId = userId; self.details = details; self.targetSubjects = targetSubjects; self.dailyStudyGoalMinutes = dailyStudyGoalMinutes; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }
    static func reconstruct(id: UUID, userId: UserID, details: String, targetSubjects: Set<Subject>, dailyStudyGoalMinutes: Int, createdAt: Date, lastModifiedAt: Date) -> StudyPlan { return StudyPlan(id: id, userId: userId, details: details, targetSubjects: targetSubjects, dailyStudyGoalMinutes: dailyStudyGoalMinutes, createdAt: createdAt, lastModifiedAt: lastModifiedAt) }
}

/// 学习进度领域实体 (仅为编译目的包含，实际应从 StudyProgress.swift 导入)
struct StudyProgress: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let subject: Subject
    let topicId: UUID?
    let progressPercentage: Double
    let timestamp: Date
    let totalStudyTime: TimeInterval
    let lastActivityAt: Date
    init(id: UUID = UUID(), userId: UserID, subject: Subject, topicId: UUID? = nil, progressPercentage: Double, timestamp: Date = Date(), totalStudyTime: TimeInterval = 0, lastActivityAt: Date = Date()) {
        self.id = id; self.userId = userId; self.subject = subject; self.topicId = topicId; self.progressPercentage = progressPercentage; self.timestamp = timestamp; self.totalStudyTime = totalStudyTime; self.lastActivityAt = lastActivityAt
    }
    static func reconstruct(id: UUID, userId: UserID, subject: Subject, topicId: UUID?, progressPercentage: Double, timestamp: Date, totalStudyTime: TimeInterval, lastActivityAt: Date) -> StudyProgress {
        return StudyProgress(id: id, userId: userId, subject: subject, topicId: topicId, progressPercentage: progressPercentage, timestamp: timestamp, totalStudyTime: totalStudyTime, lastActivityAt: lastActivityAt)
    }
}

/// 题目聚合根 (仅为编译目的包含，实际应从 Question.swift 导入)
struct Question: Equatable, Hashable, Identifiable, Sendable {
    let id: QuestionID
    let content: QuestionContent
    let answers: AnswerCollection
    let metadata: QuestionMetadata
    let learningState: LearningState
    // Simplified init for compilation
    init(id: QuestionID = QuestionID(), content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata = QuestionMetadata()) throws {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = LearningState()
    }
    static func reconstruct(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) -> Question {
        return Question(id: id, content: content, answers: answers, metadata: metadata, learningState: learningState)
    }
    var difficulty: Difficulty { metadata.difficulty }
    var subject: Subject { metadata.subject }
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false }
}

/// 题目内容值对象 (仅为编译目的包含，实际应从 QuestionContent.swift 导入)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    let attachments: [QuestionAttachment]
    init(text: String, attachments: [QuestionAttachment] = []) throws { self.text = text; self.attachments = attachments }
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

/// 单个答案值对象 (仅为编译目的包含，实际应从 Answer.swift 导入)
struct Answer: Codable, Sendable, Hashable {
    let text: String
    let isCorrect: Bool
    let explanation: String?
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws { self.text = text; self.isCorrect = isCorrect; self.explanation = explanation }
}

/// 答案集合值对象 (仅为编译目的包含，实际应从 AnswerCollection.swift 导入)
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer]
    init(correctAnswers: [String]) throws { self.answers = [] }
    init(options: [(text: String, isCorrect: Bool)]) throws { self.answers = [] }
    var hasCorrectAnswers: Bool { return true }
    var correctAnswers: [Answer] { return [] }
    var allAnswers: [Answer] { return [] }
    func check(_ userAnswer: String) -> AnswerResult { return AnswerResult(userAnswer: "", isCorrect: true, correctAnswers: []) }
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
        self.subject = subject; self.difficulty = difficulty; self.tags = tags; self.source = source; self.createdAt = createdAt; self.explanation = explanation
    }
}

/// 掌握程度枚举 (仅为编译目的包含，实际应从 MasteryLevel.swift 导入)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
}

/// 复习优先级枚举 (仅为编译目的包含，实际应从 ReviewPriority.swift 导入)
enum ReviewPriority: Int, Comparable, Codable, Sendable, Hashable {
    case low, medium, high
    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool { lhs.rawValue < rhs.rawValue }
    var displayName: String { rawValue }
    var color: String { "" }
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
    var accuracy: Double { 0.0 }
    var averageResponseTime: TimeInterval { 0.0 }
    func recordAttempt(isCorrect: Bool, difficulty: Difficulty, timestamp: Date, responseTime: TimeInterval = 0) -> LearningState { return self }
    func markReviewed(at date: Date) throws -> LearningState { return self }
    func updateWrongReason(_ reason: String?) -> LearningState { return self }
    func validateCanAnswer() throws { }
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false }
    func calculateNextReviewDate(difficulty: Difficulty) -> Date { return Date() }
    func calculateReviewPriority(difficulty: Difficulty, createdAt: Date) -> ReviewPriority { return .low }
    func calculateProgressPercentage() -> Double { return 0.0 }
    func identifyStrengths() -> [String] { return [] }
    func identifyWeaknesses() -> [String] { return [] }
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
    }
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

/// 标签值对象 (仅为编译目的包含，实际应从 Tag.swift 导入)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case topic, knowledgePoint, exam, subject, custom }
    init(_ value: String, type: TagType = .custom) throws { self.value = value; self.type = type }
}

/// 用户领域错误 (仅为编译目的包含，实际应从 UserDomainError.swift 导入)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case userNotFound
    // Simplified for compilation
    var description: String {
        switch self {
        case .userNotFound: return "User not found."
        }
    }
    var errorDescription: String? { return description }
}

/// 题目领域错误 (仅为编译目的包含，实际应从 QuestionDomainError.swift 导入)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    // Simplified for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        }
    }
    var errorDescription: String? { return description }
}

/// 查询协议 (仅为编译目的包含，实际应从 Query.swift 导入)
protocol Query: Hashable, Sendable {}

/// 查询处理器协议 (仅为编译目的包含，实际应从 QueryHandler.swift 导入)
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query
    associatedtype R
    func handle(_ query: Q) async throws -> R
}

// MARK: - Study Queries (仅为编译目的包含，实际应从 StudyQueries.swift 导入)
struct GetStudySessionByIdQuery: Query { let sessionId: UUID }
struct GetUserStudySessionsQuery: Query { let userId: UserID; let subject: Subject?; let sessionType: String? }
struct GetStudyProgressSummaryQuery: Query { let userId: UserID; let subject: Subject?; let topicId: UUID? }
struct GetStudyHistoryQuery: Query { let userId: UserID; let startDate: Date?; let endDate: Date?; let limit: Int? }
struct GetStudyPlanQuery: Query { let userId: UserID }
struct GetRecommendedQuestionsQuery: Query { let userId: UserID; let count: Int; let subject: Subject?; let excludeQuestionIds: Set<QuestionID>? }


// MARK: - Study Repositories (仅为编译目的包含，实际应从 Core/Domain/Repositories 导入)

/// 学习会话聚合仓储接口 (仅为编译目的包含，实际应从 StudySessionAggregateRepository.swift 导入)
protocol StudySessionAggregateRepository: Sendable {
    func save(_ session: StudySession) async throws
    func find(by id: UUID) async throws -> StudySession?
    func find(by userId: UserID, subject: Subject?, sessionType: String?) async throws -> [StudySession]
    func delete(_ session: StudySession) async throws
}

/// 学习进度仓储接口 (仅为编译目的包含，实际应从 StudyProgressRepository.swift 导入)
protocol StudyProgressRepository: Sendable {
    func save(_ progress: StudyProgress) async throws
    func find(by userId: UserID, subject: Subject, topicId: UUID?) async throws -> StudyProgress?
    func findRecent(userId: UserID, limit: Int) async throws -> [StudyProgress]
}

/// 学习计划仓储接口 (仅为编译目的包含，实际应从 StudyPlanRepository.swift 导入)
protocol StudyPlanRepository: Sendable {
    func save(_ plan: StudyPlan) async throws
    func find(by userId: UserID) async throws -> StudyPlan?
}

/// 题目聚合仓储接口 (仅为编译目的包含，实际应从 QuestionAggregateRepository.swift 导入)
protocol QuestionAggregateRepository: Sendable {
    func find(by id: QuestionID) async throws -> Question?
    func findQuestionsNeedingReview() async throws -> [Question]
    func findAll() async throws -> [Question] // For simplicity in GetRecommendedQuestionsQueryHandler
}


/// 根据ID获取学习会话查询处理器
/// 负责处理 `GetStudySessionByIdQuery`，从仓储中获取单个学习会话。
struct GetStudySessionByIdQueryHandler: QueryHandler {
    typealias Q = GetStudySessionByIdQuery
    typealias R = StudySession? // 返回可选的 StudySession 实体

    private let studySessionRepository: StudySessionAggregateRepository // 依赖注入仓储

    /// 初始化查询处理器
    /// - Parameter studySessionRepository: 学习会话聚合仓储的实例。
    init(studySessionRepository: StudySessionAggregateRepository) {
        self.studySessionRepository = studySessionRepository
    }

    /// 处理 `GetStudySessionByIdQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `StudySession` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetStudySessionByIdQuery) async throws -> StudySession? {
        return try await studySessionRepository.find(by: query.sessionId)
    }
}

/// 获取用户所有学习会话查询处理器
/// 负责处理 `GetUserStudySessionsQuery`，从仓储中获取用户的所有学习会话历史。
struct GetUserStudySessionsQueryHandler: QueryHandler {
    typealias Q = GetUserStudySessionsQuery
    typealias R = [StudySession] // 返回 StudySession 实体数组

    private let studySessionRepository: StudySessionAggregateRepository

    init(studySessionRepository: StudySessionAggregateRepository) {
        self.studySessionRepository = studySessionRepository
    }

    /// 处理 `GetUserStudySessionsQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 符合条件的所有 `StudySession` 实体列表。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetUserStudySessionsQuery) async throws -> [StudySession] {
        return try await studySessionRepository.find(
            by: query.userId,
            subject: query.subject,
            sessionType: query.sessionType
        )
    }
}

/// 获取学习进度摘要查询处理器
/// 负责处理 `GetStudyProgressSummaryQuery`，从仓储中获取用户的学习进度摘要。
struct GetStudyProgressSummaryQueryHandler: QueryHandler {
    typealias Q = GetStudyProgressSummaryQuery
    typealias R = StudyProgress? // 返回可选的 StudyProgress 实体

    private let studyProgressRepository: StudyProgressRepository

    init(studyProgressRepository: StudyProgressRepository) {
        self.studyProgressRepository = studyProgressRepository
    }

    /// 处理 `GetStudyProgressSummaryQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `StudyProgress` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetStudyProgressSummaryQuery) async throws -> StudyProgress? {
        // 假设 topicId 为 nil 时，表示查询某个学科的总进度
        guard let subject = query.subject else {
            // 如果没有指定学科，这里可能需要更复杂的逻辑来汇总所有学科的进度
            // 或者抛出错误，取决于业务需求。为简化，这里假设必须指定学科。
            throw UserDomainError.userNotFound // 示例错误，实际应定义更具体的错误
        }
        return try await studyProgressRepository.find(
            by: query.userId,
            subject: subject,
            topicId: query.topicId
        )
    }
}

/// 获取学习历史查询处理器
/// 负责处理 `GetStudyHistoryQuery`，从仓储中获取用户在指定时间范围内的学习活动历史。
struct GetStudyHistoryQueryHandler: QueryHandler {
    typealias Q = GetStudyHistoryQuery
    typealias R = [StudySession] // 返回 StudySession 实体数组，代表历史记录

    private let studySessionRepository: StudySessionAggregateRepository

    init(studySessionRepository: StudySessionAggregateRepository) {
        self.studySessionRepository = studySessionRepository
    }

    /// 处理 `GetStudyHistoryQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 符合条件的所有 `StudySession` 实体列表。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetStudyHistoryQuery) async throws -> [StudySession] {
        // 由于 StudySessionRepository 没有直接按日期范围查询的方法，
        // 这里简化为获取所有会话并在内存中过滤。
        // 在实际项目中，仓储层应提供更优化的查询方法。
        var sessions = try await studySessionRepository.find(
            by: query.userId,
            subject: nil, // 获取所有学科的会话
            sessionType: nil // 获取所有类型的会话
        )

        // 根据开始日期过滤
        if let startDate = query.startDate {
            sessions = sessions.filter { $0.startTime >= startDate }
        }

        // 根据结束日期过滤
        if let endDate = query.endDate {
            sessions = sessions.filter { $0.startTime <= endDate }
        }

        // 根据限制数量排序并截取
        if let limit = query.limit {
            sessions.sort { $0.startTime > $1.startTime } // 按时间倒序
            return Array(sessions.prefix(limit))
        }

        return sessions
    }
}

/// 获取学习计划查询处理器
/// 负责处理 `GetStudyPlanQuery`，从仓储中获取用户的学习计划。
struct GetStudyPlanQueryHandler: QueryHandler {
    typealias Q = GetStudyPlanQuery
    typealias R = StudyPlan? // 返回可选的 StudyPlan 实体

    private let studyPlanRepository: StudyPlanRepository

    init(studyPlanRepository: StudyPlanRepository) {
        self.studyPlanRepository = studyPlanRepository
    }

    /// 处理 `GetStudyPlanQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 找到的 `StudyPlan` 实体实例，如果不存在则为 `nil`。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetStudyPlanQuery) async throws -> StudyPlan? {
        return try await studyPlanRepository.find(by: query.userId)
    }
}

/// 获取推荐题目查询处理器
/// 负责处理 `GetRecommendedQuestionsQuery`，根据用户的学习状态和偏好获取推荐题目。
struct GetRecommendedQuestionsQueryHandler: QueryHandler {
    typealias Q = GetRecommendedQuestionsQuery
    typealias R = [QuestionID] // 返回推荐的题目ID列表

    private let questionRepository: QuestionAggregateRepository // 依赖注入题目仓储

    init(questionRepository: QuestionAggregateRepository) {
        self.questionRepository = questionRepository
    }

    /// 处理 `GetRecommendedQuestionsQuery` 查询。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 推荐的题目ID列表。
    /// - Throws: 持久化相关的错误。
    func handle(_ query: GetRecommendedQuestionsQuery) async throws -> [QuestionID] {
        // 1. 获取所有需要复习的题目
        var recommendedQuestions = try await questionRepository.findQuestionsNeedingReview()

        // 2. 如果复习题目不足，补充新题目或未掌握的题目
        if recommendedQuestions.count < query.count {
            // 获取所有题目
            let allQuestions = try await questionRepository.findAll()

            // 过滤掉已在推荐列表中的题目
            let existingRecommendedIds = Set(recommendedQuestions.map { $0.id })
            let availableQuestions = allQuestions.filter { !existingRecommendedIds.contains($0.id) }

            // 优先添加未掌握的题目
            let unmasteredQuestions = availableQuestions.filter { $0.masteryLevel != .mastered }
                                                        .sorted { $0.reviewPriority.rawValue > $1.reviewPriority.rawValue } // 优先级高的在前

            // 补充到推荐列表
            for question in unmasteredQuestions {
                if recommendedQuestions.count < query.count {
                    recommendedQuestions.append(question)
                } else {
                    break
                }
            }

            // 如果仍然不足，随机添加其他题目
            if recommendedQuestions.count < query.count {
                let remainingCount = query.count - recommendedQuestions.count
                let otherQuestions = availableQuestions.filter { !Set(recommendedQuestions.map { $0.id }).contains($0.id) }
                                                        .shuffled() // 随机打乱
                recommendedQuestions.append(contentsOf: otherQuestions.prefix(remainingCount))
            }
        }

        // 3. 应用学科过滤 (如果指定)
        if let subject = query.subject {
            recommendedQuestions = recommendedQuestions.filter { $0.subject == subject }
        }

        // 4. 排除指定题目 (如果指定)
        if let excludeIds = query.excludeQuestionIds {
            recommendedQuestions = recommendedQuestions.filter { !excludeIds.contains($0.id) }
        }

        // 5. 截取到所需数量
        return Array(recommendedQuestions.prefix(query.count)).map { $0.id }
    }
}

