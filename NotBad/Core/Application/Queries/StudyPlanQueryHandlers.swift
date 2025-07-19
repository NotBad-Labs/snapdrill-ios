//
//  StudyPlanQueryHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 和 Core/Application/Queries 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan
// import NotBadCoreDomainErrors // 包含 DomainError, StudyPlanDomainError
// import NotBadCoreApplicationQueriesStudyPlanQueries // 包含 GetStudyPlanByIDQuery, GetAllStudyPlansForUserQuery, StudyPlanQueryError

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

/// 学习计划领域实体 (仅为编译目的包含，实际应从 StudyPlan.swift 导入)
struct StudyPlan: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    let userId: UserID
    let details: String
    let targetSubjects: Set<Subject>
    let dailyStudyGoalMinutes: Int
    let createdAt: Date
    let lastModifiedAt: Date

    init(
        id: UUID = UUID(),
        userId: UserID,
        details: String,
        targetSubjects: Set<Subject>,
        dailyStudyGoalMinutes: Int,
        createdAt: Date = Date(),
        lastModifiedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.details = details
        self.targetSubjects = targetSubjects
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
        self.createdAt = createdAt
        self.lastModifiedAt = lastModifiedAt
    }

    static func reconstruct(
        id: UUID,
        userId: UserID,
        details: String,
        targetSubjects: Set<Subject>,
        dailyStudyGoalMinutes: Int,
        createdAt: Date,
        lastModifiedAt: Date
    ) -> StudyPlan {
        return StudyPlan(
            id: id,
            userId: userId,
            details: details,
            targetSubjects: targetSubjects,
            dailyStudyGoalMinutes: dailyStudyGoalMinutes,
            createdAt: createdAt,
            lastModifiedAt: lastModifiedAt
        )
    }
}

/// 领域错误基础协议 (仅为编译目的包含，实际应从 DomainError.swift 导入)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 学习计划领域错误 (仅为编译目的包含，实际应从 StudyPlanDomainError.swift 导入)
enum StudyPlanDomainError: DomainError {
    case studyPlanNotFound(UUID) // 学习计划未找到
    case invalidStudyPlanData(String) // 学习计划数据无效，包含具体原因
    case duplicateStudyPlan(UserID, String) // 用户已存在同名学习计划
    case goalExceededLimits(String) // 学习目标超出合理范围
    case noTargetSubjects // 学习计划未指定目标学科

    var description: String {
        switch self {
        case .studyPlanNotFound(let id):
            return "学习计划ID '\(id.uuidString)' 未找到。"
        case .invalidStudyPlanData(let reason):
            return "学习计划数据无效: \(reason)。"
        case .duplicateStudyPlan(let userId, let planName):
            return "用户 '\(userId.rawValue)' 已存在名为 '\(planName)' 的学习计划。"
        case .goalExceededLimits(let message):
            return "学习目标超出合理范围: \(message)。"
        case .noTargetSubjects:
            return "学习计划必须指定至少一个目标学科。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 学习计划查询相关的错误类型 (仅为编译目的包含，实际应从 StudyPlanQueries.swift 导入)
enum StudyPlanQueryError: DomainError {
    case notFound(UUID) // 查询的实体未找到
    case invalidQueryParameters(String) // 查询参数无效
    case dataRetrievalFailed(String) // 数据检索失败

    var description: String {
        switch self {
        case .notFound(let id):
            return "未找到ID为 '\(id.uuidString)' 的学习计划。"
        case .invalidQueryParameters(let reason):
            return "学习计划查询参数无效: \(reason)。"
        case .dataRetrievalFailed(let reason):
            return "学习计划数据检索失败: \(reason)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

// MARK: - StudyPlan 查询定义 (仅为编译目的包含，实际应从 StudyPlanQueries.swift 导入)

/// 根据ID和用户ID获取单个学习计划的查询。
struct GetStudyPlanByIDQuery: Sendable {
    let id: UUID
    let userId: UserID

    /// 初始化一个新的根据ID获取学习计划的查询。
    /// - Parameters:
    ///   - id: 要获取的学习计划的ID。
    ///   - userId: 学习计划所属的用户ID。
    init(id: UUID, userId: UserID) {
        self.id = id
        self.userId = userId
    }
}

/// 获取某个用户所有学习计划的查询。
struct GetAllStudyPlansForUserQuery: Sendable {
    let userId: UserID

    /// 初始化一个新的获取用户所有学习计划的查询。
    /// - Parameter userId: 要获取其学习计划的用户ID。
    init(userId: UserID) {
        self.userId = userId
    }
}

// MARK: - StudyPlan 查询处理器协议

/// 定义处理 `GetStudyPlanByIDQuery` 的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol GetStudyPlanByIDQueryHandler: Sendable {
    /// 处理根据ID获取学习计划的查询。
    /// - Parameter query: `GetStudyPlanByIDQuery` 实例。
    /// - Returns: 匹配的 `StudyPlan` 实体实例。
    /// - Throws: `StudyPlanQueryError.notFound` 如果学习计划不存在，或 `StudyPlanQueryError.dataRetrievalFailed` 如果数据检索失败。
    func handle(_ query: GetStudyPlanByIDQuery) async throws -> StudyPlan
}

/// 定义处理 `GetAllStudyPlansForUserQuery` 的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol GetAllStudyPlansForUserQueryHandler: Sendable {
    /// 处理获取某个用户所有学习计划的查询。
    /// - Parameter query: `GetAllStudyPlansForUserQuery` 实例。
    /// - Returns: 包含该用户所有 `StudyPlan` 实体实例的数组。如果用户没有学习计划，则返回空数组。
    /// - Throws: `StudyPlanQueryError.dataRetrievalFailed` 如果数据检索失败。
    func handle(_ query: GetAllStudyPlansForUserQuery) async throws -> [StudyPlan]
}

/// 聚合所有学习计划查询处理器的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyPlanQueryHandlers: GetStudyPlanByIDQueryHandler, GetAllStudyPlansForUserQueryHandler, Sendable {
    // 这个协议本身不定义任何方法，它只是一个组合协议，
    // 使得可以通过一个单一的类型来引用所有学习计划相关的查询处理器。
}

