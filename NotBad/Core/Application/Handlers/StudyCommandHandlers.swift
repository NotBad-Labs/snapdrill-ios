//
//  StudyCommandHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层和领域层类型导入 (这些类型应在各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 StartStudySessionCommand 等
// import NotBadCoreApplicationHandlers // 包含 CommandHandler 协议
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession (聚合根)
// import NotBadCoreDomainEntitiesStudyStudyProgress // 包含 StudyProgress (实体)
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan (实体)
// import NotBadCoreDomainRepositoriesStudySessionAggregateRepository // 包含 StudySessionAggregateRepository 协议
// import NotBadCoreDomainRepositoriesStudyProgressRepository // 包含 StudyProgressRepository 协议
// import NotBadCoreDomainRepositoriesStudyPlanRepository // 包含 StudyPlanRepository 协议
// import NotBadCoreDomainErrorsStudyDomainError // 包含 StudyDomainError
// import NotBadCoreDomainErrorsQuestionDomainError // 包含 QuestionDomainError
// import NotBadCoreDomainErrorsUserDomainError // 包含 UserDomainError

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
    case general = "综合"
    var displayName: String { rawValue }
    static func findCoreSubject(byName name: String) -> Subject? { return nil }
}

/// 学习会话中的题目尝试记录 (简化版)
struct StudySessionQuestionAttempt: Codable, Hashable, Sendable {
    let questionId: QuestionID
    let userAnswer: String
    let isCorrect: Bool
    let responseTime: TimeInterval
    let timestamp: Date
}

/// 学习会话领域实体 (聚合根) (简化版)
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
    static func reconstruct(id: UUID, userId: UserID, startTime: Date, endTime: Date?, subject: Subject?, sessionType: String, questionIds: Set<QuestionID>, answeredQuestions: [QuestionID: StudySessionQuestionAttempt], isCompleted: Bool) -> StudySession {
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: answeredQuestions, isCompleted: isCompleted)
    }
    func endSession(at endTime: Date, isCompleted: Bool) throws -> StudySession {
        guard self.endTime == nil else { throw StudyDomainError.invalidStudySessionState("会话已结束") }
        return StudySession(id: id, userId: userId, startTime: startTime, endTime: endTime, subject: subject, sessionType: sessionType, questionIds: questionIds, answeredQuestions: answeredQuestions, isCompleted: isCompleted)
    }
}

/// 学习进度领域实体 (简化版)
struct StudyProgress: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let subject: Subject
    let topicId: UUID?
    private(set) var progressPercentage: Double
    private(set) var timestamp: Date
    private(set) var totalStudyTime: TimeInterval
    private(set) var lastActivityAt: Date

    init(id: UUID = UUID(), userId: UserID, subject: Subject, topicId: UUID? = nil, progressPercentage: Double, timestamp: Date = Date(), totalStudyTime: TimeInterval = 0, lastActivityAt: Date = Date()) {
        self.id = id; self.userId = userId; self.subject = subject; self.topicId = topicId; self.progressPercentage = progressPercentage; self.timestamp = timestamp; self.totalStudyTime = totalStudyTime; self.lastActivityAt = lastActivityAt
    }
    static func reconstruct(id: UUID, userId: UserID, subject: Subject, topicId: UUID?, progressPercentage: Double, timestamp: Date, totalStudyTime: TimeInterval, lastActivityAt: Date) -> StudyProgress {
        return StudyProgress(id: id, userId: userId, subject: subject, topicId: topicId, progressPercentage: progressPercentage, timestamp: timestamp, totalStudyTime: totalStudyTime, lastActivityAt: lastActivityAt)
    }
    func updateProgress(newPercentage: Double, timeSpent: TimeInterval) -> StudyProgress {
        return StudyProgress(id: id, userId: userId, subject: subject, topicId: topicId, progressPercentage: max(0.0, min(1.0, newPercentage)), timestamp: Date(), totalStudyTime: totalStudyTime + timeSpent, lastActivityAt: Date())
    }
}

/// 学习计划领域实体 (简化版)
struct StudyPlan: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let createdAt: Date
    private(set) var details: String?
    private(set) var targetSubjects: Set<Subject>
    private(set) var dailyStudyGoalMinutes: Int
    private(set) var lastModifiedAt: Date

    init(id: UUID = UUID(), userId: UserID, createdAt: Date = Date(), details: String? = nil, targetSubjects: Set<Subject> = [], dailyStudyGoalMinutes: Int = 0, lastModifiedAt: Date = Date()) {
        self.id = id; self.userId = userId; self.createdAt = createdAt; self.details = details; self.targetSubjects = targetSubjects; self.dailyStudyGoalMinutes = dailyStudyGoalMinutes; self.lastModifiedAt = lastModifiedAt
    }
    static func reconstruct(id: UUID, userId: UserID, createdAt: Date, details: String?, targetSubjects: Set<Subject>, dailyStudyGoalMinutes: Int, lastModifiedAt: Date) -> StudyPlan {
        return StudyPlan(id: id, userId: userId, createdAt: createdAt, details: details, targetSubjects: targetSubjects, dailyStudyGoalMinutes: dailyStudyGoalMinutes, lastModifiedAt: lastModifiedAt)
    }
    func update(details: String?, targetSubjects: Set<Subject>?, dailyStudyGoalMinutes: Int?) -> StudyPlan {
        return StudyPlan(id: id, userId: userId, createdAt: createdAt, details: details ?? self.details, targetSubjects: targetSubjects ?? self.targetSubjects, dailyStudyGoalMinutes: dailyStudyGoalMinutes ?? self.dailyStudyGoalMinutes, lastModifiedAt: Date())
    }
}

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 学习领域错误 (简化版)
enum StudyDomainError: DomainError {
    case studySessionNotFound
    case studyPlanNotFound
    case studyProgressNotFound
    case invalidStudySessionState(String)
    case genericStudyError(String)

    var description: String {
        switch self {
        case .studySessionNotFound: return "学习会话未找到。"
        case .studyPlanNotFound: return "学习计划未找到。"
        case .studyProgressNotFound: return "学习进度未找到。"
        case .invalidStudySessionState(let reason): return "学习会话状态无效: \(reason)。"
        case .genericStudyError(let message): return "学习相关错误: \(message)。"
        }
    }
    var errorDescription: String? { return description }
}

/// 题目领域错误 (简化版)
enum QuestionDomainError: DomainError {
    case questionNotFound
    var description: String { "题目未找到。" }
    var errorDescription: String? { return description }
}

/// 用户领域错误 (简化版)
enum UserDomainError: DomainError {
    case userNotFound
    var description: String { "用户未找到。" }
    var errorDescription: String? { return description }
}

/// 仓储基础协议 (简化版)
protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Codable & Hashable & Sendable
    func save(_ entity: Entity) async throws
    func find(by id: Entity.ID) async throws -> Entity?
    func delete(_ entity: Entity) async throws
}

/// 学习会话聚合仓储接口 (简化版)
protocol StudySessionAggregateRepository: Repository where Entity == StudySession {
    func find(by userId: UserID) async throws -> [StudySession]
    func find(by userId: UserID, subject: Subject) async throws -> [StudySession]
}

/// 学习进度仓储接口 (简化版)
protocol StudyProgressRepository: Repository where Entity == StudyProgress {
    func find(by userId: UserID, subject: Subject, topicId: UUID?) async throws -> StudyProgress?
    func findAll(by userId: UserID) async throws -> [StudyProgress]
}

/// 学习计划仓储接口 (简化版)
protocol StudyPlanRepository: Repository where Entity == StudyPlan {
    func find(by userId: UserID) async throws -> StudyPlan?
}

/// 命令协议 (简化版)
protocol Command: Hashable, Sendable {}

/// 命令处理器协议 (简化版)
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command
    func handle(_ command: C) async throws
}

/// 学习命令：开始新的学习会话 (简化版)
struct StartStudySessionCommand: Command {
    let userId: UserID
    let sessionType: String
    let questionIds: Set<QuestionID>
    let subject: Subject?
}

/// 学习命令：结束学习会话 (简化版)
struct EndStudySessionCommand: Command {
    let sessionId: UUID
    let isCompleted: Bool
}

/// 学习命令：更新学习进度 (简化版)
struct UpdateStudyProgressCommand: Command {
    let userId: UserID
    let subject: Subject
    let topicId: UUID?
    let progressPercentage: Double
    let timeSpent: TimeInterval
}

/// 学习命令：更新学习计划 (简化版)
struct UpdateStudyPlanCommand: Command {
    let userId: UserID
    let details: String?
    let targetSubjects: Set<Subject>?
    let dailyStudyGoalMinutes: Int?
}


// MARK: - 学习命令处理器

/// 开始学习会话命令处理器
/// 负责处理 `StartStudySessionCommand`，创建 `StudySession` 聚合根并保存。
struct StartStudySessionCommandHandler: CommandHandler {
    typealias C = StartStudySessionCommand

    private let studySessionRepository: StudySessionAggregateRepository

    /// 初始化命令处理器
    /// - Parameter studySessionRepository: 学习会话聚合仓储的实例。
    init(studySessionRepository: StudySessionAggregateRepository) {
        self.studySessionRepository = studySessionRepository
    }

    /// 处理 `StartStudySessionCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func handle(_ command: StartStudySessionCommand) async throws {
        // 1. 使用领域层的工厂方法或初始化器创建 StudySession 聚合根
        let newSession = StudySession(
            userId: command.userId,
            sessionType: command.sessionType,
            questionIds: command.questionIds,
            subject: command.subject
        )

        // 2. 通过仓储保存 StudySession 聚合根
        try await studySessionRepository.save(newSession)

        // 3. (可选) 发布领域事件，例如 StudySessionStartedEvent
        // EventBus.shared.publish(StudySessionStartedEvent(sessionId: newSession.id, userId: newSession.userId))
    }
}

/// 结束学习会话命令处理器
/// 负责处理 `EndStudySessionCommand`，更新现有学习会话的状态。
struct EndStudySessionCommandHandler: CommandHandler {
    typealias C = EndStudySessionCommand

    private let studySessionRepository: StudySessionAggregateRepository

    /// 初始化命令处理器
    /// - Parameter studySessionRepository: 学习会话聚合仓储的实例。
    init(studySessionRepository: StudySessionAggregateRepository) {
        self.studySessionRepository = studySessionRepository
    }

    /// 处理 `EndStudySessionCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func handle(_ command: EndStudySessionCommand) async throws {
        // 1. 通过仓储获取要结束的学习会话聚合根
        guard let existingSession = try await studySessionRepository.find(by: command.sessionId) else {
            throw StudyDomainError.studySessionNotFound
        }

        // 2. 调用 StudySession 聚合根的业务方法来结束会话
        let updatedSession = try existingSession.endSession(at: Date(), isCompleted: command.isCompleted)

        // 3. 通过仓储保存更新后的 StudySession 聚合根
        try await studySessionRepository.save(updatedSession)

        // 4. (可选) 发布领域事件，例如 StudySessionCompletedEvent
        // EventBus.shared.publish(StudySessionCompletedEvent(sessionId: updatedSession.id, userId: updatedSession.userId, duration: updatedSession.duration))
    }
}

/// 更新学习进度命令处理器
/// 负责处理 `UpdateStudyProgressCommand`，更新用户的学习进度。
struct UpdateStudyProgressCommandHandler: CommandHandler {
    typealias C = UpdateStudyProgressCommand

    private let studyProgressRepository: StudyProgressRepository

    /// 初始化命令处理器
    /// - Parameter studyProgressRepository: 学习进度仓储的实例。
    init(studyProgressRepository: StudyProgressRepository) {
        self.studyProgressRepository = studyProgressRepository
    }

    /// 处理 `UpdateStudyProgressCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func handle(_ command: UpdateStudyProgressCommand) async throws {
        // 1. 尝试查找现有学习进度
        let existingProgress = try await studyProgressRepository.find(
            by: command.userId,
            subject: command.subject,
            topicId: command.topicId
        )

        let updatedProgress: StudyProgress
        if let progress = existingProgress {
            // 2. 如果存在，则更新现有进度
            updatedProgress = progress.updateProgress(
                newPercentage: command.progressPercentage,
                timeSpent: command.timeSpent
            )
        } else {
            // 3. 如果不存在，则创建新的学习进度
            updatedProgress = StudyProgress(
                userId: command.userId,
                subject: command.subject,
                topicId: command.topicId,
                progressPercentage: command.progressPercentage,
                totalStudyTime: command.timeSpent
            )
        }

        // 4. 通过仓储保存或更新学习进度
        try await studyProgressRepository.save(updatedProgress)

        // 5. (可选) 发布领域事件，例如 StudyProgressUpdatedEvent
        // EventBus.shared.publish(StudyProgressUpdatedEvent(userId: command.userId, subject: command.subject, progress: updatedProgress.progressPercentage))
    }
}

/// 更新学习计划命令处理器
/// 负责处理 `UpdateStudyPlanCommand`，更新用户的学习计划。
struct UpdateStudyPlanCommandHandler: CommandHandler {
    typealias C = UpdateStudyPlanCommand

    private let studyPlanRepository: StudyPlanRepository

    /// 初始化命令处理器
    /// - Parameter studyPlanRepository: 学习计划仓储的实例。
    init(studyPlanRepository: StudyPlanRepository) {
        self.studyPlanRepository = studyPlanRepository
    }

    /// 处理 `UpdateStudyPlanCommand` 命令。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func handle(_ command: UpdateStudyPlanCommand) async throws {
        // 1. 尝试查找现有学习计划
        let existingPlan = try await studyPlanRepository.find(by: command.userId)

        let updatedPlan: StudyPlan
        if let plan = existingPlan {
            // 2. 如果存在，则更新现有计划
            updatedPlan = plan.update(
                details: command.details,
                targetSubjects: command.targetSubjects,
                dailyStudyGoalMinutes: command.dailyStudyGoalMinutes
            )
        } else {
            // 3. 如果不存在，则创建新的学习计划
            // 注意：这里需要确保所有非可选参数都有值，或者提供默认值
            guard let details = command.details,
                  let targetSubjects = command.targetSubjects,
                  let dailyStudyGoalMinutes = command.dailyStudyGoalMinutes else {
                throw StudyDomainError.genericStudyError("创建学习计划时缺少必要参数。")
            }
            updatedPlan = StudyPlan(
                userId: command.userId,
                details: details,
                targetSubjects: targetSubjects,
                dailyStudyGoalMinutes: dailyStudyGoalMinutes
            )
        }

        // 4. 通过仓储保存或更新学习计划
        try await studyPlanRepository.save(updatedPlan)

        // 5. (可选) 发布领域事件，例如 StudyPlanUpdatedEvent
        // EventBus.shared.publish(StudyPlanUpdatedEvent(userId: command.userId, planId: updatedPlan.id))
    }
}

