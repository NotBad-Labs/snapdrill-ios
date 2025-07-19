//
//  StudyPlan.swift
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
// import NotBadCoreDomainErrors // 包含 UserDomainError (或更通用的 DomainError)

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


/// 学习计划领域实体
/// 代表用户个性化的学习计划，包括目标学科、每日学习目标等。
/// 这是一个独立的领域实体，拥有自己的生命周期和业务行为。
struct StudyPlan: Identifiable, Hashable, Codable, Sendable {
    let id: UUID // 学习计划的唯一标识符
    let userId: UserID // 学习计划所属的用户ID
    private(set) var details: String // 学习计划的详细描述或目标（简化为字符串，实际可能是复杂结构）
    private(set) var targetSubjects: Set<Subject> // 学习计划的目标学科集合
    private(set) var dailyStudyGoalMinutes: Int // 每日学习目标（分钟）
    let createdAt: Date // 学习计划创建时间
    private(set) var lastModifiedAt: Date // 学习计划上次修改时间

    /// 初始化 StudyPlan
    /// - Parameters:
    ///   - id: 学习计划的唯一标识符，默认为新的UUID
    ///   - userId: 学习计划所属的用户ID
    ///   - details: 学习计划的详细描述
    ///   - targetSubjects: 目标学科集合
    ///   - dailyStudyGoalMinutes: 每日学习目标分钟数
    ///   - createdAt: 创建时间，默认为当前时间
    ///   - lastModifiedAt: 上次修改时间，默认为当前时间
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

    /// 重建 StudyPlan 实体（用于从存储恢复）
    /// 这是一个私有初始化方法，仅供仓储层使用，不进行业务验证。
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

    // MARK: - 业务行为 (返回新的 StudyPlan 实例)

    /// 更新学习计划的详细描述。
    /// - Parameter newDetails: 新的详细描述。
    /// - Returns: 更新后的 StudyPlan 新实例。
    func updateDetails(_ newDetails: String) -> StudyPlan {
        return StudyPlan(
            id: id,
            userId: userId,
            details: newDetails,
            targetSubjects: targetSubjects,
            dailyStudyGoalMinutes: dailyStudyGoalMinutes,
            createdAt: createdAt,
            lastModifiedAt: Date() // 更新修改时间
        )
    }

    /// 更新学习计划的目标学科集合。
    /// - Parameter newSubjects: 新的目标学科集合。
    /// - Returns: 更新后的 StudyPlan 新实例。
    func updateTargetSubjects(_ newSubjects: Set<Subject>) -> StudyPlan {
        return StudyPlan(
            id: id,
            userId: userId,
            details: details,
            targetSubjects: newSubjects,
            dailyStudyGoalMinutes: dailyStudyGoalMinutes,
            createdAt: createdAt,
            lastModifiedAt: Date() // 更新修改时间
        )
    }

    /// 更新每日学习目标分钟数。
    /// - Parameter newGoal: 新的每日学习目标分钟数。
    /// - Returns: 更新后的 StudyPlan 新实例。
    func updateDailyGoal(_ newGoal: Int) -> StudyPlan {
        return StudyPlan(
            id: id,
            userId: userId,
            details: details,
            targetSubjects: targetSubjects,
            dailyStudyGoalMinutes: newGoal,
            createdAt: createdAt,
            lastModifiedAt: Date() // 更新修改时间
        )
    }

    // 您可以根据业务需求添加更多与学习计划相关的业务行为，例如：
    // func addTargetSubject(_ subject: Subject) -> StudyPlan
    // func removeTargetSubject(_ subject: Subject) -> StudyPlan
    // func validatePlan() throws -> Bool // 验证计划的有效性
}

