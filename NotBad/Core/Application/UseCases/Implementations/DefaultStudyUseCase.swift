//
//  DefaultStudyUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationUseCasesStudyUseCase // 包含 StudyUseCase 协议
// import NotBadCoreApplicationCommandQueryBus // 包含 CommandQueryBus
// import NotBadCoreApplicationCommandsStudyCommands // 包含 StartStudySessionCommand 等
// import NotBadCoreApplicationQueriesStudyQueries // 包含 GetStudySessionByIdQuery 等
// import NotBadCoreApplicationCommandsQuestionCommands // 包含 AnswerQuestionCommand, MarkQuestionAsReviewedCommand
// import NotBadCoreApplicationQueriesQuestionQueries // 包含 GetQuestionByIdQuery
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan
// import NotBadCoreDomainEntitiesStudyStudyProgress // 包含 StudyProgress
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainEntitiesLearningStudySuggestion // 包含 StudySuggestion
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
// import NotBadCoreDomainEntitiesLearningLearningProgressAssessment // 包含 LearningProgressAssessment
// import NotBadCoreDomainEntitiesQuestion // 包含 Question (聚合根)
// import NotBadCoreDomainErrors // 包含 QuestionDomainError, UserDomainError, ApplicationError

/// 用户ID强类型 (简化版)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 题目ID强类型 (简化版)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 学科枚举 (简化版)
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

/// 难度级别枚举 (简化版)
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

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
}

/// 复习优先级枚举 (简化版)
enum ReviewPriority: Int, Comparable, Codable, Sendable, Hashable {
    case low, medium, high
    static func < (lhs: ReviewPriority, rhs: ReviewPriority) -> Bool { lhs.rawValue < rhs.rawValue }
    var displayName: String { rawValue }
    var color: String { "" }
}

/// 学习会话中的题目尝试记录 (简化版)
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

/// 学习会话领域实体 (简化版)
struct StudySession: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let startTime: Date
    let endTime: Date?
    let subject: Subject?
    let sessionType: String
    let questionIds: Set<QuestionID>
    private(set) var answeredQuestions: [QuestionID: StudySessionQuestionAttempt]
    private(set) var isCompleted: Bool

    init(id: UUID = UUID(), userId: UserID, startTime: Date = Date(), endTime: Date? = nil, subject: Subject? = nil, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt] = [:], isCompleted: Bool = false) {
        // Dummy validation for compilation
        guard !questionIds.isEmpty else { fatalError("StudySession must contain at least one question ID.") }
        self.id = id; self.userId = userId; self.startTime = startTime; self.endTime = endTime; self.subject = subject; self.sessionType = sessionType; self.questionIds = questionIds; self.answeredQuestions = answeredQuestions; self.isCompleted = isCompleted
    }
    static func reconstruct(id: UUID, userId: UserID, startTime: Date, endTime: Date?, subject: Subject?, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt], isCompleted: Bool) -> StudySession {
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: answeredQuestions, isCompleted: isCompleted)
    }
    func recordQuestionAttempt(questionId: QuestionID, userAnswer: String, isCorrect: Bool, responseTime: TimeInterval) throws -> StudySession {
        var newAnsweredQuestions = answeredQuestions
        let attempt = StudySessionQuestionAttempt(questionId: questionId, userAnswer: userAnswer, isCorrect: isCorrect, responseTime: responseTime)
        newAnsweredQuestions[questionId] = attempt
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: newAnsweredQuestions, isCompleted: isCompleted)
    }
    func endSession(at endTime: Date, isCompleted: Bool) throws -> StudySession {
        guard self.endTime == nil else { throw QuestionDomainError.invalidStateForOperation("Session already ended.") }
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: answeredQuestions, isCompleted: isCompleted)
    }
    var duration: TimeInterval { 0.0 }
    var answeredQuestionCount: Int { 0 }
    var correctQuestionCount: Int { 0 }
    var sessionAccuracy: Double { 0.0 }
    var averageResponseTime: TimeInterval { 0.0 }
    var allQuestionIDs: [QuestionID] { [] }
    var allAnsweredAttempts: [StudySessionQuestionAttempt] { [] }
}

/// 学习计划领域实体 (简化版)
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
    func updateDetails(_ newDetails: String) -> StudyPlan { return self }
    func updateTargetSubjects(_ newSubjects: Set<Subject>) -> StudyPlan { return self }
    func updateDailyGoal(_ newGoal: Int) -> StudyPlan { return self }
}

/// 学习进度领域实体 (简化版)
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
    func updateProgress(newPercentage: Double, timeSpent: TimeInterval) -> StudyProgress { return self }
    func recordActivity(at activityTime: Date) -> StudyProgress { return self }
}

/// 题目统计信息值对象 (简化版)
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
    var learningEfficiencyScore: Double { 0.0 }
    var isProblematic: Bool { false }
    var isStrength: Bool { false }
}

/// 学习建议值对象 (简化版)
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

/// 学习进度评估结果值对象 (简化版)
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

/// 题目聚合根 (简化版)
struct Question: Equatable, Hashable, Identifiable, Sendable {
    let id: QuestionID
    let content: QuestionContent
    let answers: AnswerCollection
    let metadata: QuestionMetadata
    let learningState: LearningState
    init(id: QuestionID = QuestionID(), content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata = QuestionMetadata()) throws {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = LearningState()
    }
    static func reconstruct(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) -> Question {
        return Question(id: id, content: content, answers: answers, metadata: metadata, learningState: learningState)
    }
    func answerQuestion(_ userAnswer: String, responseTime: TimeInterval = 0) throws -> (result: AnswerResult, updatedQuestion: Question) {
        return (AnswerResult(userAnswer: userAnswer, isCorrect: true, correctAnswers: []), self)
    }
    func markAsReviewed() throws -> Question { return self }
    var difficulty: Difficulty { metadata.difficulty }
    var subject: Subject { metadata.subject }
    var masteryLevel: MasteryLevel { learningState.masteryLevel }
    var tags: Set<Tag> { metadata.tags }
    var createdAt: Date { metadata.createdAt }
    func getStatisticsSummary() -> QuestionStatistics { return QuestionStatistics(questionId: id, totalAttempts: 0, correctAttempts: 0, accuracy: 0, masteryLevel: .unknown, reviewCount: 0, lastReviewedAt: nil, averageResponseTime: 0, createdAt: Date()) }
    func getStudySuggestion() -> StudySuggestion { return StudySuggestion(message: "", actionItems: [], estimatedTime: 0, difficulty: .easy, priority: .low) }
}

/// 题目内容值对象 (简化版)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    let attachments: [QuestionAttachment]
    init(text: String, attachments: [QuestionAttachment] = []) throws { self.text = text; self.attachments = attachments }
}

/// 题目附件值对象 (简化版)
struct QuestionAttachment: Codable, Sendable, Hashable {
    let id: UUID
    let type: AttachmentType
    let url: URL
    let description: String?
    enum AttachmentType: String, Codable, Sendable { case image, audio, video, document }
}

/// 答案集合值对象 (简化版)
struct AnswerCollection: Codable, Sendable, Hashable {
    private let answers: [Answer]
    init(correctAnswers: [String]) throws { self.answers = [] }
    init(options: [(text: String, isCorrect: Bool)]) throws { self.answers = [] }
    func check(_ userAnswer: String) -> AnswerResult { return AnswerResult(userAnswer: userAnswer, isCorrect: true, correctAnswers: []) }
}

/// 单个答案值对象 (简化版)
struct Answer: Codable, Sendable, Hashable {
    let text: String
    let isCorrect: Bool
    let explanation: String?
    init(text: String, isCorrect: Bool, explanation: String? = nil) throws { self.text = text; self.isCorrect = isCorrect; self.explanation = explanation }
}

/// 题目元数据值对象 (简化版)
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
    func withDifficulty(_ newDifficulty: Difficulty) -> QuestionMetadata { return self }
}

/// 学习状态值对象 (简化版)
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
    var accuracy: Double { 0.0 }
    var averageResponseTime: TimeInterval { 0.0 }
}

/// 答题结果值对象 (简化版)
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

/// 标签值对象 (简化版)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case topic, knowledgePoint, exam, subject, custom }
    init(_ value: String, type: TagType = .custom) throws { self.value = value; self.type = type }
}

/// 题目领域错误 (简化版)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    case userNotFound // Added for compilation
    var description: String {
        switch self {
        case .invalidStateForOperation(let op): return "Invalid state for operation: \(op)"
        case .userNotFound: return "User not found."
        }
    }
    var errorDescription: String? { return description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case handlerNotFound(String)
    case invalidHandlerType(String)
    case unknownError(String)
    case notAuthenticated
    case unauthorizedAccess
    case notFound(String)

    var description: String {
        switch self {
        case .handlerNotFound(let name): return "未找到命令/查询处理器: \(name)。"
        case .invalidHandlerType(let name): return "处理器类型不匹配: \(name)。"
        case .unknownError(let message): return "发生未知错误: \(message)。"
        case .notAuthenticated: return "用户未认证或会话已过期。"
        case .unauthorizedAccess: return "未授权访问。"
        case .notFound(let msg): return "未找到请求的资源: \(msg)。"
        }
    }
    var errorDescription: String? { return description }
}

/// 命令协议 (简化版)
protocol Command: Hashable, Sendable {}

/// 查询协议 (简化版)
protocol Query: Hashable, Sendable {}

/// 命令处理器协议 (简化版)
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

/// 查询处理器协议 (简化版)
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query
    associatedtype R
    func handle(_ query: Q) async throws -> R
}

/// 命令查询总线 (简化版)
actor CommandQueryBus {
    private var commandHandlers: [String: AnyCommandHandlerWrapper] = [:]
    private var queryHandlers: [String: AnyQueryHandlerWrapper] = [:]

    @discardableResult
    func register<C: Command, H: CommandHandler>(handler: H, for commandType: C.Type) -> CommandQueryBus where H.C == C {
        let key = String(describing: commandType)
        commandHandlers[key] = AnyCommandHandlerWrapper(handler)
        return self
    }

    @discardableResult
    func register<Q: Query, R, H: QueryHandler>(handler: H, for queryType: Q.Type) -> CommandQueryBus where H.Q == Q, H.R == R {
        let key = String(describing: queryType)
        queryHandlers[key] = AnyQueryHandlerWrapper(handler)
        return self
    }

    func execute<C: Command>(_ command: C) async throws {
        let key = String(describing: type(of: command))
        guard let handler = commandHandlers[key] as? AnyCommandHandlerWrapper else {
            throw ApplicationError.handlerNotFound("Command handler for \(key) not found.")
        }
        guard let specificHandler = handler.base as? any CommandHandler<C> else {
            throw ApplicationError.invalidHandlerType("Command handler for \(key) is of an unexpected type.")
        }
        try await specificHandler.handle(command)
    }

    func execute<Q: Query, R>(_ query: Q) async throws -> R {
        let key = String(describing: type(of: query))
        guard let handler = queryHandlers[key] as? AnyQueryHandlerWrapper else {
            throw ApplicationError.handlerNotFound("Query handler for \(key) not found.")
        }
        guard let specificHandler = handler.base as? any QueryHandler<Q, R> else {
            throw ApplicationError.invalidHandlerType("Query handler for \(key) is of an unexpected type or return type.")
        }
        return try await specificHandler.handle(query)
    }

    private protocol AnyCommandHandler { var base: Any { get } }
    private struct AnyCommandHandlerWrapper: AnyCommandHandler {
        let base: Any
        init<C: Command, H: CommandHandler>(_ handler: H) where H.C == C { self.base = handler }
    }
    private protocol AnyQueryHandler { var base: Any { get } }
    private struct AnyQueryHandlerWrapper: AnyQueryHandler {
        let base: Any
        init<Q: Query, R, H: QueryHandler>(_ handler: H) where H.Q == Q, H.R == R { self.base = handler }
    }
}

// MARK: - Study 相关的命令和查询定义 (简化版)

/// 学习命令：开始学习会话
struct StartStudySessionCommand: Command {
    let userId: UserID
    let sessionType: String
    let questionIds: Set<QuestionID>
    let subject: Subject?
}

/// 学习命令：记录题目尝试
struct RecordQuestionAttemptInSessionCommand: Command {
    let sessionId: UUID
    let questionId: QuestionID
    let userAnswer: String
    let isCorrect: Bool
    let responseTime: TimeInterval
}

/// 学习命令：结束学习会话
struct EndStudySessionCommand: Command {
    let sessionId: UUID
    let isCompleted: Bool
}

/// 学习命令：更新学习进度
struct UpdateStudyProgressCommand: Command {
    let userId: UserID
    let subject: Subject
    let topicId: UUID?
    let newPercentage: Double
    let timeSpent: TimeInterval
}

/// 学习命令：创建或更新学习计划
struct CreateOrUpdateStudyPlanCommand: Command {
    let userId: UserID
    let planId: UUID? // Optional: if updating existing plan
    let details: String
    let targetSubjects: Set<Subject>
    let dailyStudyGoalMinutes: Int
}

/// 学习查询：获取学习会话
struct GetStudySessionByIdQuery: Query {
    let sessionId: UUID
}

/// 学习查询：获取用户的所有学习会话
struct GetUserStudySessionsQuery: Query {
    let userId: UserID
    let subject: Subject?
    let sessionType: String?
}

/// 学习查询：获取学习进度摘要
struct GetStudyProgressSummaryQuery: Query {
    let userId: UserID
    let subject: Subject?
    let topicId: UUID?
}

/// 学习查询：获取学习计划
struct GetStudyPlanQuery: Query {
    let userId: UserID
}

/// 学习查询：获取推荐题目
struct GetRecommendedQuestionsQuery: Query {
    let userId: UserID
    let count: Int
    let subject: Subject?
    let excludeQuestionIds: Set<QuestionID>?
}

/// 题目查询：根据ID获取题目
struct GetQuestionByIdQuery: Query {
    let questionId: QuestionID
}

/// 题目查询：获取题目统计摘要
struct GetQuestionStatisticsQuery: Query {
    let questionId: QuestionID
}

/// 题目查询：获取学习建议
struct GetStudySuggestionQuery: Query {
    let questionId: QuestionID
}

/// 学习用例接口 (简化版)
protocol StudyUseCase: Sendable {
    func startStudySession(
        userId: UserID,
        sessionType: String,
        questionIds: Set<QuestionID>,
        subject: Subject?
    ) async throws -> UUID
    func recordQuestionAttemptInSession(
        sessionId: UUID,
        questionId: QuestionID,
        userAnswer: String,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) async throws
    func endStudySession(sessionId: UUID, isCompleted: Bool) async throws
    func getStudySessionDetails(sessionId: UUID) async throws -> StudySession
    func getUserStudySessions(
        userId: UserID,
        subject: Subject?,
        sessionType: String?
    ) async throws -> [StudySession]
    func getStudyProgressSummary(
        userId: UserID,
        subject: Subject?,
        topicId: UUID?
    ) async throws -> StudyProgress?
    func updateStudyProgress(
        userId: UserID,
        subject: Subject,
        topicId: UUID?,
        newPercentage: Double,
        timeSpent: TimeInterval
    ) async throws
    func getStudyPlan(userId: UserID) async throws -> StudyPlan?
    func createOrUpdateStudyPlan(
        userId: UserID,
        details: String,
        targetSubjects: Set<Subject>,
        dailyStudyGoalMinutes: Int
    ) async throws -> UUID
    func getRecommendedQuestions(
        userId: UserID,
        count: Int,
        subject: Subject?,
        excludeQuestionIds: Set<QuestionID>?
    ) async throws -> [QuestionID]
    func getQuestionStudySuggestion(questionId: QuestionID) async throws -> StudySuggestion
    func getQuestionStatistics(questionId: QuestionID) async throws -> QuestionStatistics
    func assessQuestionLearningProgress(questionId: QuestionID) async throws -> LearningProgressAssessment
}


/// 默认学习用例实现
/// 负责协调用户学习、练习和复习相关的命令和查询，
/// 通过 `CommandQueryBus` 与底层处理器交互。
/// 遵循 `StudyUseCase` 协议。
struct DefaultStudyUseCase: StudyUseCase {

    private let commandBus: CommandQueryBus // 用于发送命令
    private let queryBus: CommandQueryBus // 用于发送查询

    /// 初始化默认学习用例
    /// - Parameters:
    ///   - commandBus: 命令总线实例。
    ///   - queryBus: 查询总线实例。
    init(commandBus: CommandQueryBus, queryBus: CommandQueryBus) {
        self.commandBus = commandBus
        self.queryBus = queryBus
    }

    /// 开始一个新的学习会话。
    /// - Parameters:
    ///   - userId: 发起会话的用户ID。
    ///   - sessionType: 会话类型（例如 "练习", "复习", "模拟考试"）。
    ///   - questionIds: 本次会话包含的题目ID列表。
    ///   - subject: 会话所属的学科，可选。
    /// - Returns: 新创建的学习会话ID。
    /// - Throws: `ApplicationError.unauthorizedAccess` 或其他相关错误。
    func startStudySession(
        userId: UserID,
        sessionType: String,
        questionIds: Set<QuestionID>,
        subject: Subject?
    ) async throws -> UUID {
        let command = StartStudySessionCommand(
            userId: userId,
            sessionType: sessionType,
            questionIds: questionIds,
            subject: subject
        )
        try await commandBus.execute(command)
        // 假设 StartStudySessionCommand 的处理器会返回会话ID，这里简化为生成一个UUID
        return UUID() // 实际应由 CommandHandler 返回
    }

    /// 记录学习会话中的题目答题尝试。
    /// 此方法会同时更新学习会话的记录和题目的学习状态。
    /// - Parameters:
    ///   - sessionId: 当前学习会话的ID。
    ///   - questionId: 答题的题目ID。
    ///   - userAnswer: 用户提交的答案。
    ///   - isCorrect: 答题是否正确。
    ///   - responseTime: 答题响应时间（秒）。
    /// - Throws: `ApplicationError.notFound` 如果会话或题目不存在，
    ///           或 `QuestionDomainError` 如果答题操作无效。
    func recordQuestionAttemptInSession(
        sessionId: UUID,
        questionId: QuestionID,
        userAnswer: String,
        isCorrect: Bool,
        responseTime: TimeInterval
    ) async throws {
        // 1. 记录到学习会话 (通过 StudySessionCommand)
        let sessionCommand = RecordQuestionAttemptInSessionCommand(
            sessionId: sessionId,
            questionId: questionId,
            userAnswer: userAnswer,
            isCorrect: isCorrect,
            responseTime: responseTime
        )
        try await commandBus.execute(sessionCommand)

        // 2. 更新题目自身的学习状态 (通过 QuestionCommand)
        // 注意：这里需要确保 Question 聚合根的 answerQuestion 方法能够被调用
        // 并且其内部会更新 learningState 并保存
        let questionCommand = AnswerQuestionCommand(
            questionId: questionId,
            userAnswer: userAnswer,
            responseTime: responseTime
        )
        try await commandBus.execute(questionCommand)
    }

    /// 结束一个学习会话。
    /// - Parameters:
    ///   - sessionId: 要结束的学习会话ID。
    ///   - isCompleted: 会话是否正常完成。
    /// - Throws: `ApplicationError.notFound` 如果会话不存在，
    ///           或 `QuestionDomainError` 如果会话已结束。
    func endStudySession(sessionId: UUID, isCompleted: Bool) async throws {
        let command = EndStudySessionCommand(sessionId: sessionId, isCompleted: isCompleted)
        try await commandBus.execute(command)
    }

    /// 获取指定学习会话的详情。
    /// - Parameter sessionId: 要获取详情的学习会话ID。
    /// - Returns: 学习会话的 `StudySession` 实体。
    /// - Throws: `ApplicationError.notFound` 如果会话不存在，
    ///           或 `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getStudySessionDetails(sessionId: UUID) async throws -> StudySession {
        let query = GetStudySessionByIdQuery(sessionId: sessionId)
        guard let session = try await queryBus.execute(query) as StudySession? else {
            throw ApplicationError.notFound("学习会话 \(sessionId.uuidString) 未找到。")
        }
        return session
    }

    /// 获取用户的所有学习会话历史。
    /// - Parameters:
    ///   - userId: 用户ID。
    ///   - subject: 可选的学科过滤。
    ///   - sessionType: 可选的会话类型过滤。
    /// - Returns: 符合条件的所有学习会话列表。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getUserStudySessions(
        userId: UserID,
        subject: Subject?,
        sessionType: String?
    ) async throws -> [StudySession] {
        let query = GetUserStudySessionsQuery(
            userId: userId,
            subject: subject,
            sessionType: sessionType
        )
        return try await queryBus.execute(query) as [StudySession]
    }

    /// 获取用户的学习进度摘要。
    /// - Parameters:
    ///   - userId: 用户ID。
    ///   - subject: 可选的学科过滤。
    ///   - topicId: 可选的主题ID过滤。
    /// - Returns: 用户的学习进度摘要 `StudyProgress` 实体。
    /// - Throws: `ApplicationError.notFound` 如果进度不存在，
    ///           或 `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getStudyProgressSummary(
        userId: UserID,
        subject: Subject?,
        topicId: UUID?
    ) async throws -> StudyProgress? {
        let query = GetStudyProgressSummaryQuery(
            userId: userId,
            subject: subject,
            topicId: topicId
        )
        return try await queryBus.execute(query) as StudyProgress?
    }

    /// 更新用户的学习进度。
    /// - Parameters:
    ///   - userId: 用户ID。
    ///   - subject: 所属学科。
    ///   - topicId: 可选的主题ID。
    ///   - newPercentage: 新的进度百分比 (0.0 - 1.0)。
    ///   - timeSpent: 本次学习活动花费的时间（秒）。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限修改。
    func updateStudyProgress(
        userId: UserID,
        subject: Subject,
        topicId: UUID?,
        newPercentage: Double,
        timeSpent: TimeInterval
    ) async throws {
        let command = UpdateStudyProgressCommand(
            userId: userId,
            subject: subject,
            topicId: topicId,
            newPercentage: newPercentage,
            timeSpent: timeSpent
        )
        try await commandBus.execute(command)
    }

    /// 获取用户的学习计划。
    /// - Parameter userId: 用户ID。
    /// - Returns: 用户的 `StudyPlan` 实体，如果不存在则为 `nil`。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getStudyPlan(userId: UserID) async throws -> StudyPlan? {
        let query = GetStudyPlanQuery(userId: userId)
        return try await queryBus.execute(query) as StudyPlan?
    }

    /// 创建或更新用户的学习计划。
    /// - Parameters:
    ///   - userId: 用户ID。
    ///   - details: 学习计划的详细描述。
    ///   - targetSubjects: 目标学科集合。
    ///   - dailyStudyGoalMinutes: 每日学习目标分钟数。
    /// - Throws: `ApplicationError.unauthorizedAccess` 或其他相关错误。
    func createOrUpdateStudyPlan(
        userId: UserID,
        details: String,
        targetSubjects: Set<Subject>,
        dailyStudyGoalMinutes: Int
    ) async throws -> UUID {
        // 首先尝试获取现有学习计划，如果存在则更新，否则创建
        let existingPlan = try await getStudyPlan(userId: userId)
        let planId = existingPlan?.id

        let command = CreateOrUpdateStudyPlanCommand(
            userId: userId,
            planId: planId,
            details: details,
            targetSubjects: targetSubjects,
            dailyStudyGoalMinutes: dailyStudyGoalMinutes
        )
        try await commandBus.execute(command)
        return planId ?? UUID() // 实际应由 CommandHandler 返回新创建的ID
    }

    /// 获取推荐题目列表。
    /// - Parameters:
    ///   - userId: 用户ID。
    ///   - count: 推荐题目数量。
    ///   - subject: 可选的学科偏好。
    ///   - excludeQuestionIds: 要排除的题目ID，可选。
    /// - Returns: 推荐的题目ID列表。
    /// - Throws: `ApplicationError.unauthorizedAccess` 或其他相关错误。
    func getRecommendedQuestions(
        userId: UserID,
        count: Int,
        subject: Subject?,
        excludeQuestionIds: Set<QuestionID>?
    ) async throws -> [QuestionID] {
        let query = GetRecommendedQuestionsQuery(
            userId: userId,
            count: count,
            subject: subject,
            excludeQuestionIds: excludeQuestionIds
        )
        return try await queryBus.execute(query) as [QuestionID]
    }

    /// 获取单个题目的学习建议。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 题目的学习建议 `StudySuggestion` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func getQuestionStudySuggestion(questionId: QuestionID) async throws -> StudySuggestion {
        let query = GetStudySuggestionQuery(questionId: questionId)
        guard let suggestion = try await queryBus.execute(query) as StudySuggestion? else {
            throw ApplicationError.notFound("题目 \(questionId.rawValue) 未找到学习建议。")
        }
        return suggestion
    }

    /// 获取单个题目的学习统计信息。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 题目的学习统计 `QuestionStatistics` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func getQuestionStatistics(questionId: QuestionID) async throws -> QuestionStatistics {
        let query = GetQuestionStatisticsQuery(questionId: questionId)
        guard let stats = try await queryBus.execute(query) as QuestionStatistics? else {
            throw ApplicationError.notFound("题目 \(questionId.rawValue) 未找到统计信息。")
        }
        return stats
    }

    /// 评估用户在某个题目上的学习进度。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 学习进度评估结果 `LearningProgressAssessment` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func assessQuestionLearningProgress(questionId: QuestionID) async throws -> LearningProgressAssessment {
        // 为了简化，这里直接使用 getQuestionStatistics 和 getQuestionStudySuggestion 的结果来构建评估
        let stats = try await getQuestionStatistics(questionId: questionId)
        let suggestion = try await getQuestionStudySuggestion(questionId: questionId)

        // 假设 LearningProgressAssessment 的构造器可以接受这些信息
        // 实际的评估逻辑应该在领域层（如 Question 聚合根或 LearningState 值对象）中实现
        return LearningProgressAssessment(
            currentLevel: stats.masteryLevel,
            progressPercentage: stats.masteryLevel.progressValue * 100, // 转换成百分比
            strengthAreas: stats.identifyStrengths(),
            improvementAreas: stats.identifyWeaknesses(),
            recommendations: suggestion.actionItems
        )
    }
}

