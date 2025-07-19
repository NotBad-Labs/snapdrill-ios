//
//  DefaultDashboardUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationUseCasesDashboardUseCase // 包含 DashboardUseCase 协议
// import NotBadCoreApplicationCommandQueryBus // 包含 CommandQueryBus
// import NotBadCoreApplicationQueriesUserQueries // 包含 GetUserByIdQuery
// import NotBadCoreApplicationQueriesQuestionQueries // 包含 GetAllQuestionsQuery, GetQuestionsNeedingReviewQuery, GetQuestionStatisticsQuery
// import NotBadCoreApplicationQueriesStudyQueries // 包含 GetAllStudyProgressByUserIDQuery, GetStudySessionsByUserIDQuery, GetStudyPlanByUserIDQuery
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesUser // 包含 User, UserProfile
// import NotBadCoreDomainEntitiesQuestion // 包含 Question
// import NotBadCoreDomainEntitiesStudy // 包含 StudyProgress, StudySession, StudyPlan
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
// import NotBadCoreDomainErrors // 包含 UserDomainError, QuestionDomainError, StudyDomainError
// import NotBadCoreApplicationErrorsApplicationError // 包含 ApplicationError
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel

/// 用户ID强类型 (简化版)
struct UserID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: String
    init(rawValue: String) { self.rawValue = rawValue }
    init() { self.rawValue = UUID().uuidString }
}

/// 学科枚举 (简化版)
enum Subject: String, CaseIterable, Codable, Sendable, Hashable {
    case mathematics = "数学"
    case physics = "物理"
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
}

/// 用户资料值对象 (简化版)
struct UserProfile: Codable, Sendable, Hashable {
    let displayName: String
    let avatarURL: URL?
    let bio: String?
    let registrationDate: Date
    init(displayName: String, avatarURL: URL? = nil, bio: String? = nil, registrationDate: Date = Date()) throws {
        self.displayName = displayName; self.avatarURL = avatarURL; self.bio = bio; self.registrationDate = registrationDate
    }
}

/// 用户领域实体 (聚合根) (简化版)
struct User: Identifiable, Hashable, Codable, Sendable {
    let id: UserID
    let profile: UserProfile // Simplified: only profile needed for dashboard
    init(id: UserID, profile: UserProfile) { self.id = id; self.profile = profile }
}

/// 题目ID强类型 (简化版)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 题目内容值对象 (简化版)
struct QuestionContent: Codable, Sendable, Hashable {
    let text: String
    init(text: String) throws { self.text = text }
}

/// 答案集合值对象 (简化版)
struct AnswerCollection: Codable, Sendable, Hashable {
    init() {}
}

/// 题目元数据值对象 (简化版)
struct QuestionMetadata: Codable, Sendable, Hashable {
    let subject: Subject
    let difficulty: Difficulty
    let createdAt: Date
    init(subject: Subject, difficulty: Difficulty, createdAt: Date = Date()) {
        self.subject = subject; self.difficulty = difficulty; self.createdAt = createdAt
    }
}

/// 学习状态值对象 (简化版)
struct LearningState: Codable, Sendable, Hashable {
    let totalAttempts: Int
    let correctAttempts: Int
    let masteryLevel: MasteryLevel
    let lastReviewedAt: Date?
    let averageResponseTime: TimeInterval
    init(totalAttempts: Int = 0, correctAttempts: Int = 0, masteryLevel: MasteryLevel = .unknown, lastReviewedAt: Date? = nil, averageResponseTime: TimeInterval = 0) {
        self.totalAttempts = totalAttempts; self.correctAttempts = correctAttempts; self.masteryLevel = masteryLevel; self.lastReviewedAt = lastReviewedAt; self.averageResponseTime = averageResponseTime
    }
    var accuracy: Double { totalAttempts > 0 ? Double(correctAttempts) / Double(totalAttempts) : 0.0 }
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool { return false } // Simplified
}

/// 难度级别枚举 (简化版)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy, medium, hard
    var displayName: String { rawValue }
    var coefficient: Double { 1.0 }
    func isHard() -> Bool { return false }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { return true }
}

/// 题目聚合根 (简化版)
struct Question: Identifiable, Hashable, Codable, Sendable {
    let id: QuestionID
    let content: QuestionContent
    let answers: AnswerCollection
    let metadata: QuestionMetadata
    let learningState: LearningState
    init(id: QuestionID, content: QuestionContent, answers: AnswerCollection, metadata: QuestionMetadata, learningState: LearningState) {
        self.id = id; self.content = content; self.answers = answers; self.metadata = metadata; self.learningState = learningState
    }
    var difficulty: Difficulty { metadata.difficulty }
    var subject: Subject { metadata.subject }
    var masteryLevel: MasteryLevel { learningState.masteryLevel }
    var createdAt: Date { metadata.createdAt }
    func getStatisticsSummary() -> QuestionStatistics {
        return QuestionStatistics(questionId: id, totalAttempts: learningState.totalAttempts, correctAttempts: learningState.correctAttempts, accuracy: learningState.accuracy, masteryLevel: learningState.masteryLevel, reviewCount: 0, lastReviewedAt: learningState.lastReviewedAt, averageResponseTime: learningState.averageResponseTime, createdAt: metadata.createdAt)
    }
    func needsReview(basedOn difficulty: Difficulty, at currentDate: Date) -> Bool {
        return learningState.needsReview(basedOn: difficulty, at: currentDate)
    }
}

/// 学习进度领域实体 (简化版)
struct StudyProgress: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let subject: Subject
    let progressPercentage: Double
    let totalStudyTime: TimeInterval
    let lastActivityAt: Date
    init(id: UUID = UUID(), userId: UserID, subject: Subject, progressPercentage: Double, totalStudyTime: TimeInterval, lastActivityAt: Date) {
        self.id = id; self.userId = userId; self.subject = subject; self.progressPercentage = progressPercentage; self.totalStudyTime = totalStudyTime; self.lastActivityAt = lastActivityAt
    }
}

/// 学习会话领域实体 (简化版)
struct StudySession: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let startTime: Date
    let endTime: Date?
    let sessionType: String
    let questionIds: Set<QuestionID>
    let isCompleted: Bool
    init(id: UUID = UUID(), userId: UserID, startTime: Date, endTime: Date? = nil, sessionType: String, questionIds: Set<QuestionID>, isCompleted: Bool = false) {
        self.id = id; self.userId = userId; self.startTime = startTime; self.endTime = endTime; self.sessionType = sessionType; self.questionIds = questionIds; self.isCompleted = isCompleted
    }
}

/// 学习计划领域实体 (简化版)
struct StudyPlan: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let dailyStudyGoalMinutes: Int
    init(id: UUID = UUID(), userId: UserID, dailyStudyGoalMinutes: Int) {
        self.id = id; self.userId = userId; self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
    }
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
}


/// 用户领域错误 (简化版)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case userNotFound
    var description: String { "User not found." }
    var errorDescription: String? { description }
}

/// 题目领域错误 (简化版)
enum QuestionDomainError: Error, CustomStringConvertible, LocalizedError {
    case invalidStateForOperation(String)
    var description: String { "Question error." }
    var errorDescription: String? { description }
}

/// 学习领域错误 (简化版)
enum StudyDomainError: Error, CustomStringConvertible, LocalizedError {
    case studySessionNotFound
    case studyPlanNotFound
    case studyProgressNotFound
    var description: String { "Study error." }
    var errorDescription: String? { description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case handlerNotFound(String)
    case invalidHandlerType(String)
    case unknownError(String)
    case notAuthenticated

    var description: String {
        switch self {
        case .handlerNotFound(let name): return "未找到命令/查询处理器: \(name)。"
        case .invalidHandlerType(let name): return "处理器类型不匹配: \(name)。"
        case .unknownError(let message): return "发生未知错误: \(message)。"
        case .notAuthenticated: return "用户未认证或会话已过期。"
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
    private var commandHandlers: [String: Any] = [:]
    private var queryHandlers: [String: Any] = [:]

    @discardableResult
    func register<C: Command, H: CommandHandler>(handler: H, for commandType: C.Type) -> CommandQueryBus where H.C == C {
        let key = String(describing: commandType)
        commandHandlers[key] = handler
        return self
    }

    @discardableResult
    func register<Q: Query, R, H: QueryHandler>(handler: H, for queryType: Q.Type) -> CommandQueryBus where H.Q == Q, H.R == R {
        let key = String(describing: queryType)
        queryHandlers[key] = handler
        return self
    }

    func execute<C: Command>(_ command: C) async throws {
        let key = String(describing: type(of: command))
        guard let handler = commandHandlers[key] as? any CommandHandler<C> else {
            throw ApplicationError.handlerNotFound("Command handler for \(key) not found or type mismatched.")
        }
        try await handler.handle(command)
    }

    func execute<Q: Query, R>(_ query: Q) async throws -> R {
        let key = String(describing: type(of: query))
        guard let handler = queryHandlers[key] as? any QueryHandler<Q, R> else {
            throw ApplicationError.handlerNotFound("Query handler for \(key) not found or type mismatched.")
        }
        return try await handler.handle(query)
    }
}

// MARK: - Dashboard 相关的查询定义

/// 查询：获取仪表盘概览数据
struct GetDashboardOverviewQuery: Query {
    let userId: UserID
}

/// 查询：获取用户最近学习活动
struct GetRecentStudyActivityQuery: Query {
    let userId: UserID
    let limit: Int
}

/// 查询：获取用户学科学习统计
struct GetSubjectStudyStatisticsQuery: Query {
    let userId: UserID
}

/// 查询：获取需要复习的题目数量
struct GetReviewQuestionCountQuery: Query {
    let userId: UserID
}

/// 查询：获取用户学习计划
struct GetUserStudyPlanQuery: Query {
    let userId: UserID
}

// MARK: - Dashboard 相关的响应 DTOs (简化版)

/// 仪表盘概览数据 DTO
struct DashboardOverviewDTO: Codable, Sendable, Hashable {
    let totalQuestions: Int
    let masteredQuestions: Int
    let questionsNeedingReview: Int
    let totalStudyTimeToday: TimeInterval // 今日学习时长
    let dailyStudyGoal: Int // 每日学习目标 (分钟)
    let userDisplayName: String
    let overallProgressPercentage: Double // 整体学习进度百分比
}

/// 最近学习活动 DTO
struct RecentStudyActivityDTO: Codable, Sendable, Hashable {
    let sessionId: UUID
    let startTime: Date
    let endTime: Date?
    let sessionType: String
    let subject: Subject?
    let answeredQuestionsCount: Int
    let correctQuestionsCount: Int
}

/// 学科学习统计 DTO
struct SubjectStudyStatisticsDTO: Codable, Sendable, Hashable {
    let subject: Subject
    let totalQuestions: Int
    let masteredQuestions: Int
    let accuracy: Double
    let totalStudyTime: TimeInterval
    let progressPercentage: Double
}


/// 仪表盘用例接口
/// 定义了获取仪表盘所需各种数据的应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol DashboardUseCase: Sendable {

    /// 获取仪表盘概览数据。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 包含总题目数、已掌握题目数、待复习题目数、今日学习时长、每日学习目标和用户显示名称的 DTO。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getDashboardOverview(for userId: UserID) async throws -> DashboardOverviewDTO

    /// 获取用户最近的学习活动列表。
    /// - Parameters:
    ///   - userId: 当前用户的 ID。
    ///   - limit: 返回的活动数量限制。
    /// - Returns: 最近学习活动 DTO 数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getRecentStudyActivities(for userId: UserID, limit: Int) async throws -> [RecentStudyActivityDTO]

    /// 获取用户各学科的学习统计数据。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 学科学习统计 DTO 数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getSubjectStudyStatistics(for userId: UserID) async throws -> [SubjectStudyStatisticsDTO]

    /// 获取今日需要复习的题目列表。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 需要复习的题目聚合根数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getTodayReviewQuestions(for userId: UserID) async throws -> [Question]
}


/// 默认仪表盘用例实现
/// 负责协调仪表盘相关的查询，通过 `CommandQueryBus` 与底层处理器交互。
/// 遵循 `DashboardUseCase` 协议。
struct DefaultDashboardUseCase: DashboardUseCase {

    private let queryBus: CommandQueryBus // 用于发送查询

    /// 初始化默认仪表盘用例
    /// - Parameter queryBus: 查询总线实例。
    init(queryBus: CommandQueryBus) {
        self.queryBus = queryBus
    }

    /// 获取仪表盘概览数据。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 包含总题目数、已掌握题目数、待复习题目数、今日学习时长、每日学习目标和用户显示名称的 DTO。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getDashboardOverview(for userId: UserID) async throws -> DashboardOverviewDTO {
        // 1. 获取用户资料
        guard let user = try await queryBus.execute(GetUserByIdQuery(userId: userId)) as User? else {
            throw UserDomainError.userNotFound
        }

        // 2. 获取所有题目和需要复习的题目
        let allQuestions = try await queryBus.execute(GetAllQuestionsQuery()) as [Question]
        let questionsNeedingReview = try await queryBus.execute(GetQuestionsNeedingReviewQuery()) as [Question]

        // 3. 计算已掌握题目数量
        let masteredQuestions = allQuestions.filter { $0.masteryLevel == .mastered }.count

        // 4. 获取用户学习计划，以获取每日学习目标
        let studyPlan = try await queryBus.execute(GetUserStudyPlanQuery(userId: userId)) as StudyPlan?
        let dailyStudyGoal = studyPlan?.dailyStudyGoalMinutes ?? 0

        // 5. 计算今日学习时长 (简化：这里需要从 StudySession 中汇总，目前仅作示例)
        // 实际应用中，需要一个查询来获取今天的 StudySessions，然后汇总它们的时长
        let todayStudyTime: TimeInterval = 0 // Placeholder

        // 6. 计算整体学习进度百分比 (简化：需要汇总所有题目的学习进度)
        let overallProgressPercentage: Double = 0.0 // Placeholder

        return DashboardOverviewDTO(
            totalQuestions: allQuestions.count,
            masteredQuestions: masteredQuestions,
            questionsNeedingReview: questionsNeedingReview.count,
            totalStudyTimeToday: todayStudyTime,
            dailyStudyGoal: dailyStudyGoal,
            userDisplayName: user.profile.displayName,
            overallProgressPercentage: overallProgressPercentage
        )
    }

    /// 获取用户最近的学习活动列表。
    /// - Parameters:
    ///   - userId: 当前用户的 ID。
    ///   - limit: 返回的活动数量限制。
    /// - Returns: 最近学习活动 DTO 数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getRecentStudyActivities(for userId: UserID, limit: Int) async throws -> [RecentStudyActivityDTO] {
        // 1. 获取用户的所有学习会话
        let studySessions = try await queryBus.execute(GetStudySessionsByUserIDQuery(userId: userId)) as [StudySession]

        // 2. 筛选已完成的会话，并按时间倒序排序，然后取前 limit 个
        let recentSessions = studySessions
            .filter { $0.isCompleted && $0.endTime != nil }
            .sorted { ($0.endTime ?? Date.distantPast) > ($1.endTime ?? Date.distantPast) }
            .prefix(limit)

        // 3. 将 StudySession 实体映射为 RecentStudyActivityDTO
        let dtos: [RecentStudyActivityDTO] = try await withThrowingTaskGroup(of: RecentStudyActivityDTO?.self) { group in
            for session in recentSessions {
                group.addTask {
                    var correctCount = 0
                    // 实际中，这里可能需要查询每个 session 中的题目及其答题结果来计算正确数
                    // 为了简化，这里假设 StudySession 实体直接包含了这些信息，或者通过一个辅助查询获取
                    // 例如：let sessionDetails = try await queryBus.execute(GetStudySessionDetailsQuery(sessionId: session.id))
                    // correctCount = sessionDetails.correctlyAnsweredQuestions.count

                    return RecentStudyActivityDTO(
                        sessionId: session.id,
                        startTime: session.startTime,
                        endTime: session.endTime,
                        sessionType: session.sessionType,
                        subject: session.subject,
                        answeredQuestionsCount: session.questionIds.count,
                        correctQuestionsCount: correctCount // Placeholder
                    )
                }
            }

            var results: [RecentStudyActivityDTO] = []
            for try await dto in group {
                if let dto = dto {
                    results.append(dto)
                }
            }
            return results
        }
        
        return dtos.sorted { ($0.endTime ?? Date.distantPast) > ($1.endTime ?? Date.distantPast) }
    }

    /// 获取用户各学科的学习统计数据。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 学科学习统计 DTO 数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getSubjectStudyStatistics(for userId: UserID) async throws -> [SubjectStudyStatisticsDTO] {
        // 1. 获取用户所有学科的学习进度
        let allStudyProgress = try await queryBus.execute(GetAllStudyProgressByUserIDQuery(userId: userId)) as [StudyProgress]

        // 2. 获取所有题目，用于计算总题目数和已掌握题目数
        let allQuestions = try await queryBus.execute(GetAllQuestionsQuery()) as [Question]

        var subjectStats: [Subject: SubjectStudyStatisticsDTO] = [:]

        for progress in allStudyProgress {
            let subject = progress.subject

            // 过滤出当前学科的题目
            let questionsInSubject = allQuestions.filter { $0.subject == subject }
            let totalQuestionsInSubject = questionsInSubject.count
            let masteredQuestionsInSubject = questionsInSubject.filter { $0.masteryLevel == .mastered }.count

            // 计算该学科的平均准确率和总学习时间
            // 这部分需要更复杂的逻辑，可能需要遍历该学科所有题目的 QuestionStatistics
            var totalAccuracy: Double = 0.0
            var questionCountForAccuracy = 0
            var totalTime: TimeInterval = 0.0

            for question in questionsInSubject {
                let stats = question.getStatisticsSummary()
                if stats.totalAttempts > 0 {
                    totalAccuracy += stats.accuracy
                    questionCountForAccuracy += 1
                }
                // 这里假设 QuestionStatistics 包含单题学习时间，或者从 StudySession 中汇总
                // totalTime += stats.totalStudyTime // 如果 QuestionStatistics 包含此字段
            }

            let averageAccuracy = questionCountForAccuracy > 0 ? totalAccuracy / Double(questionCountForAccuracy) : 0.0

            let dto = SubjectStudyStatisticsDTO(
                subject: subject,
                totalQuestions: totalQuestionsInSubject,
                masteredQuestions: masteredQuestionsInSubject,
                accuracy: averageAccuracy,
                totalStudyTime: progress.totalStudyTime, // 从 StudyProgress 获取总学习时间
                progressPercentage: progress.progressPercentage // 从 StudyProgress 获取进度百分比
            )
            subjectStats[subject] = dto
        }

        return Array(subjectStats.values).sorted { $0.subject.displayName < $1.subject.displayName }
    }

    /// 获取今日需要复习的题目列表。
    /// - Parameter userId: 当前用户的 ID。
    /// - Returns: 需要复习的题目聚合根数组。
    /// - Throws: `ApplicationError.notAuthenticated` 或其他相关错误。
    func getTodayReviewQuestions(for userId: UserID) async throws -> [Question] {
        // 实际应用中，这里需要根据用户的学习进度和复习策略来筛选
        // 为了简化，这里直接调用获取所有需要复习题目的查询
        // 并且假设这个查询已经考虑了当前用户的复习需求
        let questionsNeedingReview = try await queryBus.execute(GetQuestionsNeedingReviewQuery()) as [Question]

        // 进一步筛选，确保是今天需要复习的（如果 GetQuestionsNeedingReviewQuery 没有包含日期逻辑）
        let today = Calendar.current.startOfDay(for: Date())
        let filteredQuestions = questionsNeedingReview.filter { question in
            // 假设 Question 实体内部的 needsReview 已经考虑了当前日期
            // 或者 nextReviewDate 在今天
            let nextReviewDate = Calendar.current.startOfDay(for: question.nextReviewDate)
            return question.needsReview(basedOn: question.difficulty, at: Date()) && nextReviewDate <= today
        }

        return filteredQuestions
    }
}

