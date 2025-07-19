//
//  DashboardUseCase.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesQuestion // 包含 Question
// import NotBadCoreDomainEntitiesLearningQuestionStatistics // 包含 QuestionStatistics
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

/// 题目ID强类型 (简化版)
struct QuestionID: RawRepresentable, Codable, Hashable, Sendable {
    let rawValue: UUID
    init() { self.rawValue = UUID() }
    init(rawValue: UUID) { self.rawValue = rawValue }
}

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
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
    var nextReviewDate: Date { return Date() } // Simplified for compilation
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


// MARK: - Dashboard 相关的响应 DTOs

/// 仪表盘概览数据 DTO
/// 封装了仪表盘顶部概览区域所需的数据。
struct DashboardOverviewDTO: Codable, Sendable, Hashable {
    let totalQuestions: Int // 总题目数
    let masteredQuestions: Int // 已掌握题目数
    let questionsNeedingReview: Int // 今日需要复习的题目数
    let totalStudyTimeToday: TimeInterval // 今日学习时长（秒）
    let dailyStudyGoal: Int // 每日学习目标（分钟）
    let userDisplayName: String // 用户显示名称
    let overallProgressPercentage: Double // 整体学习进度百分比 (0.0 - 1.0)
}

/// 最近学习活动 DTO
/// 封装了用户最近学习会话的简要信息。
struct RecentStudyActivityDTO: Codable, Sendable, Hashable {
    let sessionId: UUID // 学习会话ID
    let startTime: Date // 会话开始时间
    let endTime: Date? // 会话结束时间，可选
    let sessionType: String // 会话类型（例如 "练习", "复习", "模拟考试"）
    let subject: Subject? // 会话所属学科，可选
    let answeredQuestionsCount: Int // 会话中答题总数
    let correctQuestionsCount: Int // 会话中正确答题数
}

/// 学科学习统计 DTO
/// 封装了用户在特定学科上的学习统计数据。
struct SubjectStudyStatisticsDTO: Codable, Sendable, Hashable {
    let subject: Subject // 学科
    let totalQuestions: Int // 该学科总题目数
    let masteredQuestions: Int // 该学科已掌握题目数
    let accuracy: Double // 该学科的平均准确率 (0.0 - 1.0)
    let totalStudyTime: TimeInterval // 该学科的总学习时长（秒）
    let progressPercentage: Double // 该学科的学习进度百分比 (0.0 - 1.0)
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

