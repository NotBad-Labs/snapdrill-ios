//
//  DiscoveryUseCase.swift
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
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainEntitiesQuestion // 包含 Question
// import NotBadCoreDomainEntitiesSocialRecommendation // 包含 Recommendation
// import NotBadCoreDomainEntitiesSocialFeedItem // 包含 FeedItem
// import NotBadCoreDomainEntitiesSocialUserInteraction // 包含 UserInteraction
// import NotBadCoreDomainErrors // 包含 DiscoveryDomainError, UserDomainError

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

/// 标签值对象 (简化版)
struct Tag: Codable, Hashable, Sendable {
    let value: String
    let type: TagType
    enum TagType: String, Codable, Sendable { case subject }
    init(_ value: String, type: TagType = .subject) throws { self.value = value; self.type = type }
    func conflicts(with other: Tag) -> Bool { return false }
    func isCompatibleWith(subject: Subject) -> Bool { return true }
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
    let masteryLevel: MasteryLevel
    init(masteryLevel: MasteryLevel = .unknown) { self.masteryLevel = masteryLevel }
}

/// 难度级别枚举 (简化版)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy, medium, hard
    var displayName: String { rawValue }
    var coefficient: Double { 1.0 }
    func isHard() -> Bool { return false }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { return true }
}

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown, struggling, learning, improving, mastered
    var displayName: String { rawValue }
    var progressValue: Double { 0.0 }
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
    var tags: Set<Tag> { metadata.tags }
    var createdAt: Date { metadata.createdAt }
}

/// 推荐领域实体 (简化版)
struct Recommendation: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let recommendedQuestionId: QuestionID
    let score: Double
    let reason: String?
    let createdAt: Date
    init(id: UUID = UUID(), userId: UserID, recommendedQuestionId: QuestionID, score: Double, reason: String? = nil, createdAt: Date = Date()) {
        self.id = id; self.userId = userId; self.recommendedQuestionId = recommendedQuestionId; self.score = score; self.reason = reason; self.createdAt = createdAt
    }
}

/// 动态流项目领域实体 (简化版)
struct FeedItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let questionId: QuestionID
    let activityType: String
    let createdAt: Date
    let likesCount: Int
    let commentsCount: Int
    init(id: UUID = UUID(), userId: UserID, questionId: QuestionID, activityType: String, createdAt: Date = Date(), likesCount: Int = 0, commentsCount: Int = 0) {
        self.id = id; self.userId = userId; self.questionId = questionId; self.activityType = activityType; self.createdAt = createdAt; self.likesCount = likesCount; self.commentsCount = commentsCount
    }
}

/// 用户交互领域实体 (简化版)
struct UserInteraction: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let questionId: QuestionID
    let interactionType: InteractionType
    let timestamp: Date
    enum InteractionType: String, Codable, Sendable { case like, bookmark, share, comment }
    init(id: UUID = UUID(), userId: UserID, questionId: QuestionID, interactionType: InteractionType, timestamp: Date = Date()) {
        self.id = id; self.userId = userId; self.questionId = questionId; self.interactionType = interactionType; self.timestamp = timestamp
    }
}

/// 发现领域错误 (简化版)
enum DiscoveryDomainError: Error, CustomStringConvertible, LocalizedError {
    case recommendationFailed(String)
    case feedGenerationFailed(String)
    case searchFailed(String)
    case invalidInput(String)
    case questionNotFound
    case userNotFound

    var description: String {
        switch self {
        case .recommendationFailed(let reason): return "推荐失败: \(reason)。"
        case .feedGenerationFailed(let reason): return "动态流生成失败: \(reason)。"
        case .searchFailed(let reason): return "搜索失败: \(reason)。"
        case .invalidInput(let reason): return "输入无效: \(reason)。"
        case .questionNotFound: return "题目未找到。"
        case .userNotFound: return "用户未找到。"
        }
    }
    var errorDescription: String? { return description }
}

/// 用户领域错误 (简化版)
enum UserDomainError: Error, CustomStringConvertible, LocalizedError {
    case userNotFound
    var description: String { "用户未找到。" }
    var errorDescription: String? { description }
}

/// 应用层错误 (简化版)
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case notAuthenticated
    var description: String { "用户未认证或会话已过期。" }
    var errorDescription: String? { description }
}


/// 发现用例接口
/// 定义了与内容发现（如推荐、热门、搜索）相关的所有应用层功能。
/// 表现层将通过此接口与应用层进行交互，而无需了解底层命令和查询的实现细节。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol DiscoveryUseCase: Sendable {

    /// 获取个性化题目推荐。
    /// - Parameters:
    ///   - userId: 当前用户的 ID。
    ///   - count: 推荐题目的数量。
    ///   - subject: 可选的学科偏好。
    ///   - excludeQuestionIds: 要排除的题目 ID 集合，可选。
    /// - Returns: 推荐的题目聚合根数组。
    /// - Throws: `DiscoveryDomainError.recommendationFailed`, `ApplicationError.notAuthenticated`
    ///           或任何其他相关错误。
    func getRecommendedQuestions(
        for userId: UserID,
        count: Int,
        subject: Subject?,
        excludeQuestionIds: Set<QuestionID>?
    ) async throws -> [Question]

    /// 获取热门题目列表。
    /// 热门题目通常基于近期互动量（点赞、收藏、分享、评论）或答题量。
    /// - Parameters:
    ///   - limit: 返回的题目数量限制。
    ///   - subject: 可选的学科过滤。
    /// - Returns: 热门题目聚合根数组。
    /// - Throws: `DiscoveryDomainError.feedGenerationFailed` 或任何其他相关错误。
    func getTrendingQuestions(limit: Int, subject: Subject?) async throws -> [Question]

    /// 获取用户动态流。
    /// 动态流包含用户关注的人的活动、系统推荐活动等。
    /// - Parameters:
    ///   - userId: 当前用户的 ID。
    ///   - limit: 返回的动态数量限制。
    /// - Returns: 动态流项目 DTO 数组。
    /// - Throws: `DiscoveryDomainError.feedGenerationFailed`, `ApplicationError.notAuthenticated`
    ///           或任何其他相关错误。
    func getUserFeed(for userId: UserID, limit: Int) async throws -> [FeedItem]

    /// 搜索题目。
    /// - Parameters:
    ///   - searchTerm: 搜索关键词。
    ///   - subject: 可选的学科过滤。
    ///   - difficulty: 可选的难度过滤。
    ///   - tags: 可选的标签过滤。
    /// - Returns: 匹配的题目聚合根数组。
    /// - Throws: `DiscoveryDomainError.searchFailed` 或任何其他相关错误。
    func searchQuestions(
        searchTerm: String,
        subject: Subject?,
        difficulty: Difficulty?,
        tags: Set<Tag>?
    ) async throws -> [Question]

    /// 记录用户对题目的交互行为（点赞、收藏、分享、评论等）。
    /// - Parameters:
    ///   - userId: 执行交互的用户 ID。
    ///   - questionId: 被交互的题目 ID。
    ///   - interactionType: 交互类型。
    /// - Throws: `DiscoveryDomainError.invalidInput`, `ApplicationError.notAuthenticated`
    ///           或任何其他相关错误。
    func recordUserInteraction(
        userId: UserID,
        questionId: QuestionID,
        interactionType: UserInteraction.InteractionType
    ) async throws
}

