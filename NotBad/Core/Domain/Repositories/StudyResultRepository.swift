//
//  StudyResultRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesStudyStudyResult // 包含 StudyResult (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession (聚合根)
// import NotBadCoreDomainErrors // 包含 StudyDomainError (或其他通用领域错误)

/// 用户ID强类型 (仅为编译目的包含，实际应从 UserID.swift 导入)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
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
    var duration: TimeInterval {
        guard let end = endTime else { return 0 }
        return end.timeIntervalSince(startTime)
    }
    var sessionAccuracy: Double {
        guard !answeredQuestions.isEmpty else { return 0.0 }
        let correctCount = answeredQuestions.values.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(answeredQuestions.count)
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

/// 题目ID强类型 (仅为编译目的包含，实际应从 QuestionID.swift 导入)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 学习结果领域实体
/// 代表一次学习会话的总结性结果，包括准确率、用时、掌握程度变化等。
/// 这是一个独立的领域实体，用于长期跟踪用户的学习表现。
struct StudyResult: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 学习结果的唯一标识符
    let userId: UserID // 学习结果所属的用户ID
    let sessionId: UUID // 关联的学习会话ID
    let subject: Subject? // 关联的学科
    let sessionType: String // 关联的会话类型
    let startTime: Date // 会话开始时间
    let endTime: Date // 会话结束时间
    let duration: TimeInterval // 会话持续时间
    let totalQuestions: Int // 会话中总题目数
    let answeredQuestionsCount: Int // 已答题目数
    let correctQuestionsCount: Int // 正确题目数
    let accuracy: Double // 会话准确率 (0.0 - 1.0)
    let averageResponseTime: TimeInterval // 平均答题响应时间
    let performanceMetrics: [String: Double]? // 其他性能指标，例如：{"easy_accuracy": 0.9, "hard_avg_time": 60.0}
    let masteryLevelChanges: [QuestionID: (old: MasteryLevel, new: MasteryLevel)]? // 题目掌握程度变化
    let recommendations: [String]? // 基于本次结果的个性化学习建议

    /// 初始化 StudyResult
    /// - Parameters:
    ///   - id: 学习结果ID，默认为新的UUID
    ///   - userId: 用户ID
    ///   - sessionId: 关联的学习会话ID
    ///   - subject: 关联学科，可选
    ///   - sessionType: 关联会话类型
    ///   - startTime: 会话开始时间
    ///   - endTime: 会话结束时间
    ///   - duration: 会话持续时间
    ///   - totalQuestions: 总题目数
    ///   - answeredQuestionsCount: 已答题目数
    ///   - correctQuestionsCount: 正确题目数
    ///   - accuracy: 准确率
    ///   - averageResponseTime: 平均响应时间
    ///   - performanceMetrics: 性能指标，可选
    ///   - masteryLevelChanges: 掌握程度变化，可选
    ///   - recommendations: 建议，可选
    init(
        id: UUID = UUID(),
        userId: UserID,
        sessionId: UUID,
        subject: Subject?,
        sessionType: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        totalQuestions: Int,
        answeredQuestionsCount: Int,
        correctQuestionsCount: Int,
        accuracy: Double,
        averageResponseTime: TimeInterval,
        performanceMetrics: [String: Double]? = nil,
        masteryLevelChanges: [QuestionID: (old: MasteryLevel, new: MasteryLevel)]? = nil,
        recommendations: [String]? = nil
    ) {
        self.id = id
        self.userId = userId
        self.sessionId = sessionId
        self.subject = subject
        self.sessionType = sessionType
        self.startTime = startTime
        self.endTime = endTime
        self.duration = duration
        self.totalQuestions = totalQuestions
        self.answeredQuestionsCount = answeredQuestionsCount
        self.correctQuestionsCount = correctQuestionsCount
        self.accuracy = accuracy
        self.averageResponseTime = averageResponseTime
        self.performanceMetrics = performanceMetrics
        self.masteryLevelChanges = masteryLevelChanges
        self.recommendations = recommendations
    }

    /// 从 StudySession 聚合根创建 StudyResult 实体（工厂方法）
    /// - Parameters:
    ///   - session: 完整的 StudySession 聚合根
    ///   - masteryLevelChanges: 本次会话中题目掌握程度的变化
    ///   - recommendations: 基于本次会话结果的个性化学习建议
    /// - Returns: 新的 StudyResult 实体实例
    static func createFromResult(
        from session: StudySession,
        masteryLevelChanges: [QuestionID: (old: MasteryLevel, new: MasteryLevel)]? = nil,
        recommendations: [String]? = nil
    ) -> StudyResult {
        return StudyResult(
            id: UUID(), // 生成新的结果ID
            userId: session.userId,
            sessionId: session.id,
            subject: session.subject,
            sessionType: session.sessionType,
            startTime: session.startTime,
            endTime: session.endTime ?? Date(), // 如果会话未结束，使用当前时间
            duration: session.duration,
            totalQuestions: session.questionIds.count,
            answeredQuestionsCount: session.answeredQuestionsCount,
            correctQuestionsCount: session.correctQuestionCount,
            accuracy: session.sessionAccuracy,
            averageResponseTime: session.averageResponseTime,
            performanceMetrics: nil, // 可以在这里计算或从外部传入
            masteryLevelChanges: masteryLevelChanges,
            recommendations: recommendations
        )
    }

    /// 重建 StudyResult 实体（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用，不进行业务验证。
    static func reconstruct(
        id: UUID,
        userId: UserID,
        sessionId: UUID,
        subject: Subject?,
        sessionType: String,
        startTime: Date,
        endTime: Date,
        duration: TimeInterval,
        totalQuestions: Int,
        answeredQuestionsCount: Int,
        correctQuestionsCount: Int,
        accuracy: Double,
        averageResponseTime: TimeInterval,
        performanceMetrics: [String: Double]?,
        masteryLevelChanges: [QuestionID: (old: MasteryLevel, new: MasteryLevel)]?,
        recommendations: [String]?
    ) -> StudyResult {
        return StudyResult(
            id: id,
            userId: userId,
            sessionId: sessionId,
            subject: subject,
            sessionType: sessionType,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            totalQuestions: totalQuestions,
            answeredQuestionsCount: answeredQuestionsCount,
            correctQuestionsCount: correctQuestionsCount,
            accuracy: accuracy,
            averageResponseTime: averageResponseTime,
            performanceMetrics: performanceMetrics,
            masteryLevelChanges: masteryLevelChanges,
            recommendations: recommendations
        )
    }
}

/// 学习结果仓储接口
/// 定义了对 `StudyResult` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyResultRepository: Sendable {

    /// 保存一个 `StudyResult` 实体。
    /// - Parameter result: 要保存的 `StudyResult` 实体实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func save(_ result: StudyResult) async throws

    /// 根据 ID 查找一个 `StudyResult` 实体。
    /// - Parameter id: 要查找的 `StudyResult` 的唯一标识符。
    /// - Returns: 找到的 `StudyResult` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> StudyResult?

    /// 根据用户 ID 查找所有学习结果。
    /// - Parameter userId: 用户 ID。
    /// - Returns: 属于指定用户的所有 `StudyResult` 实体数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by userId: UserID) async throws -> [StudyResult]

    /// 根据用户 ID 和学科查找学习结果。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    /// - Returns: 属于指定用户和学科的所有 `StudyResult` 实体数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject) async throws -> [StudyResult]

    /// 根据用户 ID 和会话类型查找学习结果。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - sessionType: 会话类型过滤。
    /// - Returns: 属于指定用户和会话类型的所有 `StudyResult` 实体数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by userId: UserID, sessionType: String) async throws -> [StudyResult]

    /// 获取用户最近的学习结果。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - limit: 返回结果的最大数量。
    /// - Returns: 用户最近的 `StudyResult` 实体数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func findRecent(by userId: UserID, limit: Int) async throws -> [StudyResult]

    /// 删除一个 `StudyResult` 实体。
    /// - Parameter result: 要删除的 `StudyResult` 实体实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func delete(_ result: StudyResult) async throws

    // 您可以根据业务需求添加更多查询方法，例如：
    // func findByDateRange(userId: UserID, startDate: Date, endDate: Date) async throws -> [StudyResult]
    // func calculateAverageAccuracy(userId: UserID, subject: Subject?) async throws -> Double
}

