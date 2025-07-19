//
//  StudyPlanCommands.swift
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


// MARK: - StudyPlan 命令错误

/// 学习计划命令相关的错误类型。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
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

// MARK: - StudyPlan 命令定义

/// 创建学习计划命令。
/// 包含创建新学习计划所需的所有数据。
struct CreateStudyPlanCommand: Sendable {
    let userId: UserID
    let details: String
    let targetSubjects: Set<Subject>
    let dailyStudyGoalMinutes: Int

    /// 初始化一个新的创建学习计划命令。
    /// - Parameters:
    ///   - userId: 学习计划所属的用户ID。
    ///   - details: 学习计划的详细描述。
    ///   - targetSubjects: 学习计划的目标学科集合。
    ///   - dailyStudyGoalMinutes: 每日学习目标分钟数。
    init(userId: UserID, details: String, targetSubjects: Set<Subject>, dailyStudyGoalMinutes: Int) {
        self.userId = userId
        self.details = details
        self.targetSubjects = targetSubjects
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
    }
}

/// 更新学习计划命令。
/// 包含更新现有学习计划所需的所有数据。
struct UpdateStudyPlanCommand: Sendable {
    let id: UUID // 要更新的学习计划的ID
    let userId: UserID // 学习计划所属的用户ID
    let details: String? // 可选：新的详细描述
    let targetSubjects: Set<Subject>? // 可选：新的目标学科集合
    let dailyStudyGoalMinutes: Int? // 可选：新的每日学习目标分钟数

    /// 初始化一个新的更新学习计划命令。
    /// - Parameters:
    ///   - id: 要更新的学习计划的ID。
    ///   - userId: 学习计划所属的用户ID。
    ///   - details: 可选：新的详细描述。
    ///   - targetSubjects: 可选：新的目标学科集合。
    ///   - dailyStudyGoalMinutes: 可选：新的每日学习目标分钟数。
    init(id: UUID, userId: UserID, details: String? = nil, targetSubjects: Set<Subject>? = nil, dailyStudyGoalMinutes: Int? = nil) {
        self.id = id
        self.userId = userId
        self.details = details
        self.targetSubjects = targetSubjects
        self.dailyStudyGoalMinutes = dailyStudyGoalMinutes
    }
}

/// 删除学习计划命令。
/// 包含删除学习计划所需的所有数据。
struct DeleteStudyPlanCommand: Sendable {
    let id: UUID // 要删除的学习计划的ID
    let userId: UserID // 学习计划所属的用户ID

    /// 初始化一个新的删除学习计划命令。
    /// - Parameters:
    ///   - id: 要删除的学习计划的ID。
    ///   - userId: 学习计划所属的用户ID。
    init(id: UUID, userId: UserID) {
        self.id = id
        self.userId = userId
    }
}

