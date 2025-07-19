//
//  StudyQueries.swift
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
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic

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

/// 主题领域实体 (简化版)
struct Topic: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let name: String
    let subject: Subject
    // Simplified init for compilation
    init(id: UUID = UUID(), name: String, subject: Subject) { self.id = id; self.name = name; self.subject = subject }
}

// MARK: - 查询协议定义
/// 查询协议，所有查询都应遵循此协议。
/// 查询是纯粹的数据结构，只包含获取数据所需的所有输入参数，不包含任何业务逻辑。
///
/// 遵循 `Hashable` 和 `Sendable` 协议，以支持在并发环境中的安全使用和作为字典键。
protocol Query: Hashable, Sendable {}

// MARK: - 学习会话相关查询

/// 根据会话ID获取单个学习会话的查询。
struct GetStudySessionByIdQuery: Query {
    let sessionId: UUID // 要查询的学习会话ID
}

/// 获取特定用户的所有学习会话列表的查询。
struct GetUserStudySessionsQuery: Query {
    let userId: UserID // 用户ID
    let subject: Subject? // 可选的学科过滤
    let sessionType: String? // 可选的会话类型过滤 (例如 "练习", "复习")
}

// MARK: - 学习进度相关查询

/// 获取用户在特定学科或主题上的学习进度摘要的查询。
struct GetStudyProgressSummaryQuery: Query {
    let userId: UserID // 用户ID
    let subject: Subject? // 可选的学科过滤
    let topicId: UUID? // 可选的主题过滤 (如果进度是针对某个特定主题的)
}

/// 获取用户在指定时间范围内的学习活动历史的查询。
struct GetStudyHistoryQuery: Query {
    let userId: UserID // 用户ID
    let startDate: Date? // 历史记录的开始日期，可选
    let endDate: Date? // 历史记录的结束日期，可选
    let limit: Int? // 返回记录的数量限制，可选
}

// MARK: - 学习计划相关查询

/// 获取用户学习计划详情的查询。
struct GetStudyPlanQuery: Query {
    let userId: UserID // 用户ID
}

// MARK: - 推荐题目相关查询

/// 根据用户的学习状态和偏好获取推荐题目列表的查询。
struct GetRecommendedQuestionsQuery: Query {
    let userId: UserID // 用户ID
    let count: Int // 推荐题目数量
    let subject: Subject? // 可选的学科偏好
    let excludeQuestionIds: Set<QuestionID>? // 要排除的题目ID，可选
}

