//
//  CommandHandler.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  CommandHandler.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层类型导入 (这些类型应在 Core/Application 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 Command 协议

/// 命令处理器协议
/// 所有负责处理特定命令的类或结构体都应遵循此协议。
/// 处理器接收一个命令，并协调领域对象和仓储来执行相应的业务操作。
/// 处理器不包含业务逻辑，业务逻辑应封装在领域层。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全传递。
///
/// - Parameter C: 遵循 `Command` 协议的命令类型。
protocol CommandHandler<C>: Sendable {
    associatedtype C: Command // 关联类型，表示此处理器能够处理的命令类型

    /// 处理给定的命令。
    /// 此方法是异步的，因为命令处理可能涉及异步操作，如数据库访问或网络请求。
    /// - Parameter command: 要处理的命令实例。
    /// - Throws: 在命令处理过程中可能发生的任何错误（例如，领域错误或基础设施错误）。
    func handle(_ command: C) async throws
}
