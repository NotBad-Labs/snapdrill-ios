//
//  StudySessionAggregateRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession (聚合根)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainErrors // 包含 DomainError 或其他持久化相关的错误

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
}


/// 学习会话聚合仓储接口
/// 定义了对 `StudySession` 聚合根进行持久化和检索的契约。
/// 仓储是领域层与基础设施层之间的桥梁，它以聚合根为单位进行操作。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudySessionAggregateRepository: Sendable {

    /// 保存或更新一个 `StudySession` 聚合根。
    /// 如果 `StudySession` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter session: 要保存或更新的 `StudySession` 聚合根实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func save(_ session: StudySession) async throws

    /// 根据 ID 查找一个 `StudySession` 聚合根。
    /// - Parameter id: 要查找的 `StudySession` 的唯一标识符。
    /// - Returns: 找到的 `StudySession` 聚合根实例，如果不存在则为 `nil`。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> StudySession?

    /// 根据用户 ID、学科和会话类型查找 `StudySession` 聚合根列表。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 可选的学科过滤。
    ///   - sessionType: 可选的会话类型过滤（例如 "练习", "复习"）。
    /// - Returns: 符合条件的所有 `StudySession` 聚合根数组。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject?, sessionType: String?) async throws -> [StudySession]

    /// 删除一个 `StudySession` 聚合根。
    /// - Parameter session: 要删除的 `StudySession` 聚合根实例。
    /// - Throws: `Error` 或其他持久化相关的错误。
    func delete(_ session: StudySession) async throws

    // 您可以根据业务需求添加更多查询方法，例如：
    // func findRecentSessions(userId: UserID, limit: Int) async throws -> [StudySession]
    // func countSessions(userId: UserID, subject: Subject?) async throws -> Int
}

