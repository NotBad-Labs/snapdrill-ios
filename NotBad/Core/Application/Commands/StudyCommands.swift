//
//  StudyCommands.swift
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

// MARK: - 命令协议定义
/// 命令协议，所有命令都应遵循此协议。
/// 遵循 `Hashable` 和 `Sendable` 协议，以支持在并发环境中的安全使用和作为字典键。
protocol Command: Hashable, Sendable {}

// MARK: - 学习会话相关命令

/// 开始一个新的学习会话的命令。
/// 包含创建会话所需的所有信息。
struct StartStudySessionCommand: Command {
    let userId: UserID
    let sessionType: String // 例如 "练习", "复习", "模拟考试"
    let questionIds: Set<QuestionID> // 本次会话包含的题目ID列表
    let subject: Subject? // 会话所属的学科，可选
}

/// 记录学习会话中题目答题尝试的命令。
/// 用于更新会话中特定题目的答题记录。
struct RecordQuestionAttemptInSessionCommand: Command {
    let sessionId: UUID // 当前学习会话的ID
    let questionId: QuestionID // 答题的题目ID
    let userAnswer: String // 用户提交的答案
    let isCorrect: Bool // 答题是否正确
    let responseTime: TimeInterval // 答题响应时间（秒）
}

/// 结束一个学习会话的命令。
/// 用于标记会话的结束状态。
struct EndStudySessionCommand: Command {
    let sessionId: UUID // 要结束的学习会话ID
    let isCompleted: Bool // 会话是否正常完成
}

// MARK: - 学习进度相关命令

/// 更新用户学习进度的命令。
/// 用于记录用户在特定学科或主题上的学习进展。
struct UpdateStudyProgressCommand: Command {
    let userId: UserID
    let subject: Subject // 所属学科
    let topicId: UUID? // 可选的主题ID
    let newPercentage: Double // 新的进度百分比 (0.0 - 1.0)
    let timeSpent: TimeInterval // 本次学习活动花费的时间（秒）
}

// MARK: - 学习计划相关命令

/// 创建或更新用户学习计划的命令。
/// 如果 `planId` 为空，则创建新计划；否则更新现有计划。
struct CreateOrUpdateStudyPlanCommand: Command {
    let userId: UserID
    let planId: UUID? // 可选：如果更新现有计划，则提供计划ID
    let details: String // 学习计划的详细描述
    let targetSubjects: Set<Subject> // 目标学科集合
    let dailyStudyGoalMinutes: Int // 每日学习目标分钟数
}

