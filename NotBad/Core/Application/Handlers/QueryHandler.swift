//
//  QueryHandler.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  QueryHandler.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层类型导入 (这些类型应在 Core/Application 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationQueries // 包含 Query 协议

/// 查询处理器协议
/// 所有负责处理特定查询的类或结构体都应遵循此协议。
/// 处理器接收一个查询，并协调领域对象和仓储来获取所需的数据。
/// 处理器不包含业务逻辑，业务逻辑应封装在领域层。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全传递。
///
/// - Parameter Q: 遵循 `Query` 协议的查询类型。
/// - Parameter R: 查询结果的类型。
protocol QueryHandler<Q, R>: Sendable {
    associatedtype Q: Query // 关联类型，表示此处理器能够处理的查询类型
    associatedtype R // 关联类型，表示此处理器返回的查询结果类型

    /// 处理给定的查询并返回结果。
    /// 此方法是异步的，因为查询处理可能涉及异步操作，如数据库访问或网络请求。
    /// - Parameter query: 要处理的查询实例。
    /// - Returns: 查询结果。
    /// - Throws: 在查询处理过程中可能发生的任何错误（例如，领域错误或基础设施错误）。
    func handle(_ query: Q) async throws -> R
}
