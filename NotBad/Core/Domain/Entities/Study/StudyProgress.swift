//
//  StudyProgress.swift
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
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel (如果需要)
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或更通用的 DomainError)

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
    init(id: UUID = UUID(), name: String, subject: Subject) { self.id = id; self.name = name; self.subject = subject }
    static func reconstruct(id: UUID, name: String, subject: Subject, description: String?, createdAt: Date, lastModifiedAt: Date) -> Topic {
        return try! Topic(id: id, name: name, subject: subject) // Simplified for compilation
    }
}

/// 学习进度领域实体
/// 代表用户在特定学科或主题上的学习进度。
/// 这是一个独立的领域实体，用于跟踪和报告学习者的累积表现。
struct StudyProgress: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 学习进度的唯一标识符
    let userId: UserID // 学习进度所属的用户ID
    let subject: Subject // 学习进度所属的学科
    let topicId: UUID? // 可选的主题ID，如果进度是针对某个特定主题的
    private(set) var progressPercentage: Double // 学习进度百分比 (0.0 - 1.0)
    private(set) var timestamp: Date // 记录该进度的时间
    private(set) var totalStudyTime: TimeInterval // 在此学科/主题上累积的学习时间（秒）
    private(set) var lastActivityAt: Date // 最后一次学习活动时间

    /// 初始化 StudyProgress
    /// - Parameters:
    ///   - id: 学习进度的唯一标识符，默认为新的UUID
    ///   - userId: 学习进度所属的用户ID
    ///   - subject: 学习进度所属的学科
    ///   - topicId: 可选的主题ID
    ///   - progressPercentage: 学习进度百分比
    ///   - timestamp: 记录该进度的时间，默认为当前时间
    ///   - totalStudyTime: 在此学科/主题上累积的学习时间，默认为0
    ///   - lastActivityAt: 最后一次学习活动时间，默认为当前时间
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
        self.progressPercentage = max(0.0, min(1.0, progressPercentage)) // 确保在0到1之间
        self.timestamp = timestamp
        self.totalStudyTime = totalStudyTime
        self.lastActivityAt = lastActivityAt
    }

    /// 重建 StudyProgress 实体（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用，不进行业务验证。
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

    // MARK: - 业务行为 (返回新的 StudyProgress 实例)

    /// 更新学习进度。
    /// - Parameters:
    ///   - newPercentage: 新的进度百分比。
    ///   - timeSpent: 本次学习活动花费的时间（秒），将累加到总学习时间中。
    /// - Returns: 更新后的 StudyProgress 新实例。
    func updateProgress(newPercentage: Double, timeSpent: TimeInterval) -> StudyProgress {
        return StudyProgress(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            progressPercentage: max(0.0, min(1.0, newPercentage)), // 确保在0到1之间
            timestamp: Date(), // 更新为当前时间
            totalStudyTime: totalStudyTime + timeSpent, // 累加学习时间
            lastActivityAt: Date() // 更新最后活动时间
        )
    }

    /// 标记学习活动时间。
    /// - Parameter activityTime: 学习活动发生的时间。
    /// - Returns: 更新后的 StudyProgress 新实例。
    func recordActivity(at activityTime: Date) -> StudyProgress {
        return StudyProgress(
            id: id,
            userId: userId,
            subject: subject,
            topicId: topicId,
            progressPercentage: progressPercentage,
            timestamp: timestamp,
            totalStudyTime: totalStudyTime,
            lastActivityAt: activityTime // 仅更新最后活动时间
        )
    }

    // 您可以根据业务需求添加更多与学习进度相关的业务行为，例如：
    // func resetProgress() -> StudyProgress
    // func calculateEstimatedCompletionTime() -> TimeInterval
}

