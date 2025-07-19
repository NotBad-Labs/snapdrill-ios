//
//  StudyProgressRepository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesStudyStudyProgress // 包含 StudyProgress (实体)
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainErrors // 包含 AcademicDomainError (或其他通用领域错误)

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

/// 主题领域实体 (仅为编译目的包含，实际应从 Topic.swift 导入)
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    let description: String?
    let createdAt: Date
    let lastModifiedAt: Date

    init(id: UUID = UUID(), name: String, subject: Subject, description: String? = nil, createdAt: Date = Date(), lastModifiedAt: Date = Date()) {
        self.id = id; self.name = name; self.subject = subject; self.description = description; self.createdAt = createdAt; self.lastModifiedAt = lastModifiedAt
    }
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return Topic(id: id, name: name, subject: subject, description: description, createdAt: createdAt, lastModifiedAt: lastModifiedAt)
    }
}

/// 学习进度领域实体 (仅为编译目的包含，实际应从 StudyProgress.swift 导入)
struct StudyProgress: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 学习进度的唯一标识符
    let userId: UserID // 学习进度所属的用户ID
    let subject: Subject // 学习进度所属的学科
    let topicId: UUID? // 可选的主题ID，如果进度是针对某个特定主题的
    private(set) var progressPercentage: Double // 学习进度百分比 (0.0 - 1.0)
    private(set) var timestamp: Date // 记录该进度的时间
    private(set) var totalStudyTime: TimeInterval // 在此学科/主题上累积的学习时间（秒）
    private(set) var lastActivityAt: Date // 最后一次学习活动时间

    init(
        id: UUID = UUID(),
        userId: UserID,
        subject: Subject,
        topicId: UUID? = nil,
        progressPercentage: Double,
        timestamp: Date = Date(),
        totalStudyTime: TimeInterval = 0,
        lastActivityAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.subject = subject
        self.topicId = topicId
        self.progressPercentage = max(0.0, min(1.0, progressPercentage))
        self.timestamp = timestamp
        self.totalStudyTime = totalStudyTime
        self.lastActivityAt = lastActivityAt
    }

    static func reconstruct(
        id: UUID,
        userId: UserID,
        subject: Subject,
        topicId: UUID?,
        progressPercentage: Double,
        timestamp: Date,
        totalStudyTime: TimeInterval,
        lastActivityAt: Date
    ) -> StudyProgress {
        return StudyProgress(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            progressPercentage: progressPercentage,
            timestamp: timestamp,
            totalStudyTime: totalStudyTime,
            lastActivityAt: lastActivityAt
        )
    }

    func updateProgress(newPercentage: Double, timeSpent: TimeInterval) -> StudyProgress {
        return StudyProgress(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            progressPercentage: max(0.0, min(1.0, newPercentage)),
            timestamp: Date(),
            totalStudyTime: totalStudyTime + timeSpent,
            lastActivityAt: Date()
        )
    }

    func recordActivity(at activityTime: Date) -> StudyProgress {
        return StudyProgress(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            progressPercentage: progressPercentage,
            timestamp: timestamp,
            totalStudyTime: totalStudyTime,
            lastActivityAt: activityTime
        )
    }
}

/// 学术领域错误 (仅为编译目的包含，实际应从 AcademicDomainError.swift 导入)
enum AcademicDomainError: Error, CustomStringConvertible, LocalizedError {
    case studyProgressNotFound(UUID)
    case invalidStudyProgressData(String)
    case topicNotFoundForProgress(UUID)

    var description: String {
        switch self {
        case .studyProgressNotFound(let id):
            return "学习进度ID '\(id.uuidString)' 未找到。"
        case .invalidStudyProgressData(let reason):
            return "学习进度数据无效: \(reason)。"
        case .topicNotFoundForProgress(let topicId):
            return "主题ID '\(topicId.uuidString)' 未找到，无法关联学习进度。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 学习进度仓储接口
/// 定义了对 `StudyProgress` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyProgressRepository: Sendable {

    /// 保存或更新一个 `StudyProgress` 实体。
    /// 如果 `StudyProgress` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter progress: 要保存或更新的 `StudyProgress` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func save(_ progress: StudyProgress) async throws

    /// 根据 ID 查找一个 `StudyProgress` 实体。
    /// - Parameter id: 要查找的 `StudyProgress` 的唯一标识符。
    /// - Returns: 找到的 `StudyProgress` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> StudyProgress?

    /// 根据用户 ID 查找所有学习进度。
    /// - Parameter userId: 用户 ID。
    /// - Returns: 属于指定用户的所有 `StudyProgress` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID) async throws -> [StudyProgress]

    /// 根据用户 ID 和学科查找学习进度。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    /// - Returns: 属于指定用户和学科的所有 `StudyProgress` 实体数组。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject) async throws -> [StudyProgress]

    /// 根据用户 ID、学科和主题查找学习进度。
    /// - Parameters:
    ///   - userId: 用户 ID。
    ///   - subject: 学科过滤。
    ///   - topicId: 主题 ID 过滤。
    /// - Returns: 属于指定用户、学科和主题的 `StudyProgress` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID, subject: Subject, topicId: UUID) async throws -> StudyProgress?

    /// 删除一个 `StudyProgress` 实体。
    /// - Parameter progress: 要删除的 `StudyProgress` 实体实例。
    /// - Throws: `AcademicDomainError` 或其他持久化相关的错误。
    func delete(_ progress: StudyProgress) async throws

    // 您可以根据业务需求添加更多查询方法，例如：
    // func findRecentProgress(by userId: UserID, limit: Int) async throws -> [StudyProgress]
    // func calculateOverallProgress(by userId: UserID) async throws -> Double
}

