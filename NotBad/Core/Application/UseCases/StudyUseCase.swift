//
//  StudyUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan
// import NotBadCoreDomainEntitiesStudyStudyProgress // 包含 StudyProgress
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreDomainEntitiesLearningReviewPriority // 包含 ReviewPriority
// import NotBadCoreDomainEntitiesLearningStudySuggestion // 包含 StudySuggestion
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
// import NotBadCoreDomainEntitiesLearningLearningProgressAssessment // 包含 LearningProgressAssessment
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError

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
    let answeredQuestions: [QuestionID: StudySessionQuestionAttempt]
    let isCompleted: Bool

    init(id: UUID = UUID(), userId: UserID, startTime: Date = Date(), endTime: Date? = nil, subject: Subject? = nil, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt] = [:], isCompleted: Bool = false) {
        self.id = id; self.userId = userId; self.startTime = startTime; self.endTime = endTime; self.subject = subject; self.sessionType = sessionType; self.questionIds = questionIds; self.answeredQuestions = answeredQuestions; self.isCompleted = isCompleted
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

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case notAuthenticated
    case unauthorizedAccess
    case unknownError(String)
    case notFound(String) // 新增：未找到资源

    var description: String {
        switch self {
        case .notAuthenticated: return "用户未认证或会话已过期。"
        case .unauthorizedAccess: return "未授权访问。"
        case .unknownError(let msg): return "发生未知错误: \(msg)。"
        case .notFound(let msg): return "未找到请求的资源: \(msg)。"
        }
    }
    var errorDescription: String? { return description }
}


/// 学习用例接口
/// 定义了与用户学习、练习和复习相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyUseCase: Sendable {

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
    ) async throws -> UUID

    /// 记录学习会话中的题目答题尝试。
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
    ) async throws

    /// 结束一个学习会话。
    /// - Parameters:
    ///   - sessionId: 要结束的学习会话ID。
    ///   - isCompleted: 会话是否正常完成。
    /// - Throws: `ApplicationError.notFound` 如果会话不存在，
    ///           或 `QuestionDomainError` 如果会话已结束。
    func endStudySession(sessionId: UUID, isCompleted: Bool) async throws

    /// 获取指定学习会话的详情。
    /// - Parameter sessionId: 要获取详情的学习会话ID。
    /// - Returns: 学习会话的 `StudySession` 实体。
    /// - Throws: `ApplicationError.notFound` 如果会话不存在，
    ///           或 `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getStudySessionDetails(sessionId: UUID) async throws -> StudySession

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
    ) async throws -> [StudySession]

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
    ) async throws -> StudyProgress?

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
    ) async throws

    /// 获取用户的学习计划。
    /// - Parameter userId: 用户ID。
    /// - Returns: 用户的 `StudyPlan` 实体，如果不存在则为 `nil`。
    /// - Throws: `ApplicationError.unauthorizedAccess` 如果没有权限访问。
    func getStudyPlan(userId: UserID) async throws -> StudyPlan?

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
    ) async throws -> UUID

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
    ) async throws -> [QuestionID]

    /// 获取单个题目的学习建议。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 题目的学习建议 `StudySuggestion` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func getQuestionStudySuggestion(questionId: QuestionID) async throws -> StudySuggestion

    /// 获取单个题目的学习统计信息。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 题目的学习统计 `QuestionStatistics` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func getQuestionStatistics(questionId: QuestionID) async throws -> QuestionStatistics

    /// 评估用户在某个题目上的学习进度。
    /// - Parameter questionId: 题目ID。
    /// - Returns: 学习进度评估结果 `LearningProgressAssessment` 值对象。
    /// - Throws: `ApplicationError.notFound` 如果题目不存在。
    func assessQuestionLearningProgress(questionId: QuestionID) async throws -> LearningProgressAssessment
}

