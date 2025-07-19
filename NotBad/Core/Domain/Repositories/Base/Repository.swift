//
//  Repository.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainErrorsDomainError // 包含 DomainError

/// 领域错误基础协议 (简化版，实际应从 Core/Domain/Errors/DomainError.swift 导入)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

/// 题目领域错误 (简化版，实际应从 Core/Domain/Errors/QuestionDomainError.swift 导入)
// 这里仅包含一个示例错误，以满足编译要求
enum QuestionDomainError: DomainError {
    case genericRepositoryError(String) // 通用仓储错误

    var description: String {
        switch self {
        case .genericRepositoryError(let message):
            return "仓储操作失败: \(message)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}


/// 仓储基础协议
/// 定义了所有仓储通用的基本 CRUD（创建、读取、更新、删除）操作。
/// 任何具体的仓储接口（例如 `QuestionAggregateRepository`）都应继承此协议，
/// 并根据其所操作的聚合根或实体类型指定 `Entity` 类型。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全使用。
protocol Repository<Entity>: Sendable {
    associatedtype Entity: Identifiable & Codable & Hashable & Sendable // 仓储操作的实体类型

    /// 保存或更新一个实体。
    /// 如果实体已存在（通过其 `id` 判断），则更新；否则，添加。
    /// - Parameter entity: 要保存或更新的实体实例。
    /// - Throws: 任何继承自 `DomainError` 的错误，或底层持久化层抛出的错误。
    func save(_ entity: Entity) async throws

    /// 根据 ID 查找一个实体。
    /// - Parameter id: 要查找的实体的唯一标识符。
    /// - Returns: 找到的实体实例，如果不存在则为 `nil`。
    /// - Throws: 任何继承自 `DomainError` 的错误，或底层持久化层抛出的错误。
    func find(by id: Entity.ID) async throws -> Entity?

    /// 删除一个实体。
    /// - Parameter entity: 要删除的实体实例。
    /// - Throws: 任何继承自 `DomainError` 的错误，或底层持久化层抛出的错误。
    func delete(_ entity: Entity) async throws

    // 您可以根据通用需求添加更多方法，例如：
    // func findAll() async throws -> [Entity]
    // func count() async throws -> Int
}

