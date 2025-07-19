//
//  StudySessionRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesStudyStudySession // 包含 StudySession (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
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
    let id: UUID // 会话的唯一标识符
    let userId: UserID // 会话所属的用户ID
    let subject: Subject // 会话所属的学科
    private(set) var startTime: Date // 会话开始时间
    private(set) var endTime: Date? // 会话结束时间 (可选，如果会话仍在进行中)
    private(set) var durationMinutes: Int // 会话持续时间（分钟）
    private(set) var notes: String? // 会话备注
    private(set) var isCompleted: Bool // 会话是否已完成
    let createdAt: Date // 会话创建时间
    private(set) var lastModifiedAt: Date // 会话上次修改时间

    init(
        id: UUID = UUID(),
        userId: UserID,
        subject: Subject,
        startTime: Date = Date(),
        endTime: Date? = nil,
        durationMinutes: Int = 0,
        notes: String? = nil,
        isCompleted: Bool = false,
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.subject = subject
        self.startTime = startTime
        self.endTime = endTime
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.isCompleted = isCompleted
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    static func reconstruct(
        id: UUID,
        userId: UserID,
        subject: Subject,
        startTime: Date,
        endTime: Date?,
        durationMinutes: Int,
        notes: String?,
        isCompleted: Bool,
        createdAt: Date,
        lastModifiedAt: Date
    ) -> StudySession {
        return StudySession(
            id: id,
            userId: userId,
            subject: subject,
            startTime: startTime,
            endTime: endTime,
            durationMinutes: durationMinutes,
            notes: notes,
            isCompleted: isCompleted,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }

    mutating func endSession(at endDate: Date, notes: String? = nil) {
        guard self.endTime == nil else { return } // 确保会话未结束
        self.endTime = endDate
        self.durationMinutes = Int(endDate.timeIntervalSince(startTime) / 60)
        self.notes = notes ?? self.notes
        self.isCompleted = true
        self.lastModifiedAt = Date()
    }

    func updateNotes(_ newNotes: String?) -> StudySession {
        return StudySession(
            id: id, userId: userId, subject: subject, startTime: startTime, endTime: endTime,
            durationMinutes: durationMinutes, notes: newNotes, isCompleted: isCompleted,
            createdAt: createdAt, lastModifiedAt: Date()
        )
    }
}

/// 学习领域错误 (仅为编译目的包含，实际应从 StudyDomainError.swift 导入)
enum StudyDomainError: Error, CustomStringConvertible, LocalizedError {
    case studyPlanNotFound(UUID)
    case invalidStudyPlanData(String)
    case noActiveStudyPlanFound(UserID)
    case studySessionAlreadyEnded(UUID)
    case questionNotInSession(UUID, UUID)
    case invalidStudyProgress(String)
    case studySessionNotFound(UUID)
    case invalidStudySessionData(String)

    var description: String {
        switch self {
        case .studyPlanNotFound(let id):
            return "学习计划ID '\(id.uuidString)' 未找到。"
        case .invalidStudyPlanData(let reason):
            return "学习计划数据无效: \(reason)。"
        case .noActiveStudyPlanFound(let userId):
            return "用户 '\(userId.rawValue)' 没有找到活跃的学习计划。"
        case .studySessionAlreadyEnded(let sessionId):
            return "学习会话 '\(sessionId.uuidString)' 已经结束。"
        case .questionNotInSession(let questionId, let sessionId):
            return "题目ID '\(questionId.rawValue)' 不属于会话 '\(sessionId.uuidString)'。"
        case .invalidStudyProgress(let reason):
            return "学习进度数据无效: \(reason)。"
        case .studySessionNotFound(let id):
            return "学习会话ID '\(id.uuidString)' 未找到。"
        case .invalidStudySessionData(let reason):
            return "学习会话数据无效: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 学习会话仓储接口
/// 定义了对 `StudySession` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudySessionRepository: Sendable {

    /// 保存或更新一个 `StudySession` 实体。
    /// 如果 `StudySession` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter session: 要保存或更新的 `StudySession` 实体实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func save(_ session: StudySession) async throws

    /// 根据 ID 查找一个 `StudySession` 实体。
    /// - Parameter id: 要查找的 `StudySession` 的唯一标识符。
    /// - Returns: 找到的 `StudySession` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> StudySession?

    /// 根据用户 ID 查找所有学习会话。
    /// - Parameter userId: 用户 ID。
    /// - Returns: 属于指定用户的所有 `StudySession` 实体数组。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID) async throws -> [StudySession]

    /// 根据用户 ID 和学科查找学习会话。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    /// - Returns: 属于指定用户和学科的所有 `StudySession` 实体数组。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject) async throws -> [StudySession]

    /// 查找用户最近的 N 个学习会话。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - limit: 要返回的最大会话数量。
    /// - Returns: 用户最近的 `StudySession` 实体数组，按时间倒序排列。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func findRecentSessions(by userId: UserID, limit: Int) async throws -> [StudySession]

    /// 删除一个 `StudySession` 实体。
    /// - Parameter session: 要删除的 `StudySession` 实体实例。
    /// - Throws: `StudyDomainError` 或其他持久化相关的错误。
    func delete(_ session: StudySession) async throws

    // 您可以根据业务需求添加更多查询方法，例如：
    // func findSessionsByDateRange(userId: UserID, startDate: Date, endDate: Date) async throws -> [StudySession]
    // func findActiveSession(for userId: UserID) async throws -> StudySession?
}

