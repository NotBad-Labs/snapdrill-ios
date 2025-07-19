//
//  StudyPlanCommandHandlers.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 和 Core/Application/Commands 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainValueObjectsIdentityUserID // 包含 UserID
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesStudyStudyPlan // 包含 StudyPlan
// import NotBadCoreDomainErrors // 包含 DomainError, StudyPlanDomainError
// import NotBadCoreApplicationCommandsStudyPlanCommands // 包含 CreateStudyPlanCommand, UpdateStudyPlanCommand, DeleteStudyPlanCommand, StudyPlanCommandError

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

/// 学习计划命令相关的错误类型 (仅为编译目的包含，实际应从 StudyPlanCommands.swift 导入)
enum StudyPlanCommandError: DomainError {
    case validationFailed(String) // 命令参数验证失败
    case operationFailed(String) // 命令操作失败，例如数据库写入错误
    case studyPlanAlreadyExists(String) // 尝试创建已存在的学习计划
    case studyPlanNotFound(UUID) // 尝试操作不存在的学习计划

    var description: String {
        switch self {
        case .validationFailed(let reason):
            return "学习计划命令验证失败: \(reason)。"
        case .operationFailed(let reason):
            return "学习计划命令操作失败: \(reason)。"
        case .studyPlanAlreadyExists(let name):
            return "名为 '\(name)' 的学习计划已存在。"
        case .studyPlanNotFound(let id):
            return "未找到ID为 '\(id.uuidString)' 的学习计划。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

// MARK: - StudyPlan 命令定义 (仅为编译目的包含，实际应从 StudyPlanCommands.swift 导入)
/// 创建学习计划命令。
struct CreateStudyPlanCommand: Sendable {
    let userId: UserID
    let details: String
    let targetSubjects: Set<Subject>
    let dailyStudyGoalMinutes: Int
    init(userId: UserID, details: String, targetSubjects: Set<Subject>, dailyStudyGoalMinutes: Int) {
        self.userId = userId
        self.details = details
        self.targetSubjects = targetSubjects
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
    }
}

/// 更新学习计划命令。
struct UpdateStudyPlanCommand: Sendable {
    let id: UUID
    let userId: UserID
    let details: String?
    let targetSubjects: Set<Subject>?
    let dailyStudyGoalMinutes: Int?
    init(id: UUID, userId: UserID, details: String? = nil, targetSubjects: Set<Subject>? = nil, dailyStudyGoalMinutes: Int? = nil) {
        self.id = id
        self.userId = userId
        self.details = details
        self.targetSubjects = targetSubjects
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
    }
}

/// 删除学习计划命令。
struct DeleteStudyPlanCommand: Sendable {
    let id: UUID
    let userId: UserID
    init(id: UUID, userId: UserID) {
        self.id = id
        self.userId = userId
    }
}


// MARK: - StudyPlan 命令处理器协议

/// 定义处理 `CreateStudyPlanCommand` 的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol CreateStudyPlanCommandHandler: Sendable {
    /// 处理创建学习计划命令。
    /// - Parameter command: `CreateStudyPlanCommand` 实例。
    /// - Returns: 新创建的 `StudyPlan` 实体实例。
    /// - Throws: `StudyPlanCommandError` 或其他相关的领域错误。
    func handle(_ command: CreateStudyPlanCommand) async throws -> StudyPlan
}

/// 定义处理 `UpdateStudyPlanCommand` 的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol UpdateStudyPlanCommandHandler: Sendable {
    /// 处理更新学习计划命令。
    /// - Parameter command: `UpdateStudyPlanCommand` 实例。
    /// - Returns: 更新后的 `StudyPlan` 实体实例。
    /// - Throws: `StudyPlanCommandError` 或其他相关的领域错误。
    func handle(_ command: UpdateStudyPlanCommand) async throws -> StudyPlan
}

/// 定义处理 `DeleteStudyPlanCommand` 的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol DeleteStudyPlanCommandHandler: Sendable {
    /// 处理删除学习计划命令。
    /// - Parameter command: `DeleteStudyPlanCommand` 实例。
    /// - Throws: `StudyPlanCommandError` 或其他相关的领域错误。
    func handle(_ command: DeleteStudyPlanCommand) async throws
}

/// 聚合所有学习计划命令处理器的协议。
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol StudyPlanCommandHandlers: CreateStudyPlanCommandHandler, UpdateStudyPlanCommandHandler, DeleteStudyPlanCommandHandler, Sendable {
    // 这个协议本身不定义任何方法，它只是一个组合协议，
    // 使得可以通过一个单一的类型来引用所有学习计划相关的命令处理器。
}

