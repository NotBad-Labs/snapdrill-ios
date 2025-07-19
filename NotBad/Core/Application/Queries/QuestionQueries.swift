//
//  QuestionQueries.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityQuestionID // 包含 QuestionID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentDifficulty // 包含 Difficulty
// import NotBadCoreDomainEntitiesContentTag // 包含 Tag
// import NotBadCoreDomainEntitiesLearningMasteryLevel // 包含 MasteryLevel
// import NotBadCoreApplicationQueries // 包含 Query 协议

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

/// 难度级别枚举 (简化版)
enum Difficulty: String, CaseIterable, Codable, Comparable, Sendable, Hashable {
    case easy = "简单"
    case medium = "中等"
    case hard = "困难"
    var displayName: String { rawValue }
    var coefficient: Double { return 1.0 }
    func isHard() -> Bool { return false }
    static func < (lhs: Difficulty, rhs: Difficulty) -> Bool { return true }
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

/// 掌握程度枚举 (简化版)
enum MasteryLevel: String, CaseIterable, Codable, Sendable, Hashable {
    case unknown = "未知"
    case struggling = "困难"
    case learning = "学习中"
    case improving = "进步中"
    case mastered = "已掌握"
    var displayName: String { rawValue }
    var progressValue: Double { return 0.0 }
}


/// 题目查询：获取所有题目
/// 用于获取系统中所有题目的列表。
/// 遵循 `Query` 协议。
struct GetAllQuestionsQuery: Query {
    // 此查询无需额外参数
}

/// 题目查询：根据ID获取题目
/// 用于根据题目ID获取单个题目的详细信息。
/// 遵循 `Query` 协议。
struct GetQuestionByIDQuery: Query {
    let questionId: QuestionID // 要获取的题目ID
}

/// 题目查询：根据学科获取题目
/// 用于获取特定学科下的题目列表。
/// 遵循 `Query` 协议。
struct GetQuestionsBySubjectQuery: Query {
    let subject: Subject // 要筛选的学科
}

/// 题目查询：根据掌握程度获取题目
/// 用于获取特定掌握程度的题目列表。
/// 遵循 `Query` 协议。
struct GetQuestionsByMasteryLevelQuery: Query {
    let masteryLevel: MasteryLevel // 要筛选的掌握程度
}

/// 题目查询：获取需要复习的题目
/// 用于获取所有需要复习的题目列表。
/// 遵循 `Query` 协议。
struct GetQuestionsNeedingReviewQuery: Query {
    // 此查询无需额外参数
}

/// 题目查询：搜索题目
/// 用于根据关键词、学科、难度和标签进行题目搜索。
/// 遵循 `Query` 协议。
struct SearchQuestionsQuery: Query {
    let query: String // 搜索关键词
    let subject: Subject? // 可选的学科筛选
    let difficulty: Difficulty? // 可选的难度筛选
    let tags: Set<Tag>? // 可选的标签筛选

    // Hashable 和 Equatable 协议的自动实现
}

