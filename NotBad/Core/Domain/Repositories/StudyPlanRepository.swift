//
//  StudyPlanRepository.swift
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
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan
// import NotBadCoreDomainErrors // 包含 DomainError, StudyPlanDomainError

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

/// 学习计划领域错误
/// 定义了所有与学习计划相关的业务逻辑错误。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
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


/// 学习计划仓储接口
/// 定义了对 `StudyPlan` 实体进行持久化和检索的契约。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyPlanRepository: Sendable {

    /// 保存或更新一个 `StudyPlan` 实体。
    /// 如果 `StudyPlan` 已存在（通过其 ID 判断），则更新；否则，添加。
    /// - Parameter studyPlan: 要保存或更新的 `StudyPlan` 实体实例。
    /// - Throws: `StudyPlanDomainError` 或其他持久化相关的错误。
    func save(_ studyPlan: StudyPlan) async throws

    /// 根据 ID 查找一个 `StudyPlan` 实体。
    /// - Parameter id: 要查找的 `StudyPlan` 的唯一标识符。
    /// - Returns: 找到的 `StudyPlan` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `StudyPlanDomainError` 或其他持久化相关的错误。
    func find(by id: UUID) async throws -> StudyPlan?

    /// 查找指定用户的所有学习计划。
    /// - Parameter userId: 用户ID。
    /// - Returns: 指定用户的所有 `StudyPlan` 实体数组。
    /// - Throws: `StudyPlanDomainError` 或其他持久化相关的错误。
    func find(by userId: UserID) async throws -> [StudyPlan]

    /// 查找指定用户下，名称与给定名称匹配的学习计划。
    /// - Parameters:
    ///   - name: 学习计划的名称。
    ///   - userId: 用户ID。
    /// - Returns: 找到的 `StudyPlan` 实体实例，如果不存在则为 `nil`。
    /// - Throws: `StudyPlanDomainError` 或其他持久化相关的错误。
    func find(by name: String, for userId: UserID) async throws -> StudyPlan?

    /// 删除一个 `StudyPlan` 实体。
    /// - Parameter studyPlan: 要删除的 `StudyPlan` 实体实例。
    /// - Throws: `StudyPlanDomainError` 或其他持久化相关的错误。
    func delete(_ studyPlan: StudyPlan) async throws
}

