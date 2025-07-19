//
//  CommandQueryBus.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助应用层类型导入 (这些类型应在 Core/Application 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreApplicationCommands // 包含 Command 协议
// import NotBadCoreApplicationQueries // 包含 Query 协议
// import NotBadCoreApplicationHandlers // 包含 CommandHandler 和 QueryHandler 协议
// import NotBadCoreDomainErrors // 包含 QuestionDomainError (或其他通用领域错误)

/// 应用层错误 (仅为编译目的包含，实际应从 Core/Application/Errors 导入)
// Note: In a real project, this would be in its own file: Core/Application/Errors/ApplicationError.swift
enum ApplicationError: Error, CustomStringConvertible, LocalizedError, Hashable, Sendable {
    case handlerNotFound(String) // 未找到对应的处理器
    case invalidHandlerType(String) // 处理器类型不匹配
    case unknownError(String) // 未知错误

    var description: String {
        switch self {
        case .handlerNotFound(let name):
            return "未找到命令/查询处理器: \(name)。"
        case .invalidHandlerType(let name):
            return "处理器类型不匹配: \(name)。"
        case .unknownError(let message):
            return "发生未知错误: \(message)。"
        }
    }

    var errorDescription: String? {
        return description
    }
}

/// 命令查询总线
/// 这是一个 `actor`，负责安全地注册和分发命令和查询到它们对应的处理器。
/// 它作为 `Presentation` 层和 `Application` 层之间的统一接口，
/// 实现了命令查询职责分离 (CQRS) 模式中的调度机制。
actor CommandQueryBus {
    // 存储命令处理器，Key: 命令类型 (String), Value: 处理器实例 (AnyCommandHandlerWrapper)
    private var commandHandlers: [String: AnyCommandHandlerWrapper] = [:]
    // 存储查询处理器，Key: 查询类型 (String), Value: 处理器实例 (AnyQueryHandlerWrapper)
    private var queryHandlers: [String: AnyQueryHandlerWrapper] = [:]

    /// 注册一个命令处理器。
    /// - Parameter handler: 要注册的命令处理器实例。
    /// - Parameter commandType: 处理器所处理的命令类型。
    /// - Returns: `CommandQueryBus` 实例，支持链式调用。
    @discardableResult
    func register<C: Command, H: CommandHandler>(handler: H, for commandType: C.Type) -> CommandQueryBus where H.C == C {
        let key = String(describing: commandType)
        commandHandlers[key] = AnyCommandHandlerWrapper(handler)
        return self
    }

    /// 注册一个查询处理器。
    /// - Parameter handler: 要注册的查询处理器实例。
    /// - Parameter queryType: 处理器所处理的查询类型。
    /// - Returns: `CommandQueryBus` 实例，支持链式调用。
    @discardableResult
    func register<Q: Query, R, H: QueryHandler>(handler: H, for queryType: Q.Type) -> CommandQueryBus where H.Q == Q, H.R == R {
        let key = String(describing: queryType)
        queryHandlers[key] = AnyQueryHandlerWrapper(handler)
        return self
    }

    /// 执行一个命令。
    /// 查找并调用对应命令的处理器。
    /// - Parameter command: 要执行的命令实例。
    /// - Throws: `ApplicationError.handlerNotFound` 如果没有找到处理器，
    ///           `ApplicationError.invalidHandlerType` 如果处理器类型不匹配，
    ///           或命令处理器抛出的任何错误。
    func execute<C: Command>(_ command: C) async throws {
        let key = String(describing: type(of: command))
        guard let wrapper = commandHandlers[key] else {
            throw ApplicationError.handlerNotFound("Command handler for \(key) not found.")
        }
        guard let handler = wrapper.base as? any CommandHandler<C> else {
            throw ApplicationError.invalidHandlerType("Command handler for \(key) is of an unexpected type.")
        }
        try await handler.handle(command)
    }

    /// 执行一个查询并返回结果。
    /// 查找并调用对应查询的处理器。
    /// - Parameter query: 要执行的查询实例。
    /// - Returns: 查询结果。
    /// - Throws: `ApplicationError.handlerNotFound` 如果没有找到处理器，
    ///           `ApplicationError.invalidHandlerType` 如果处理器类型不匹配，
    ///           或查询处理器抛出的任何错误。
    func execute<Q: Query, R>(_ query: Q) async throws -> R {
        let key = String(describing: type(of: query))
        guard let wrapper = queryHandlers[key] else {
            throw ApplicationError.handlerNotFound("Query handler for \(key) not found.")
        }
        guard let handler = wrapper.base as? any QueryHandler<Q, R> else {
            throw ApplicationError.invalidHandlerType("Query handler for \(key) is of an unexpected type or return type.")
        }
        return try await handler.handle(query)
    }
}

// MARK: - 内部辅助类型 (用于类型擦除)

/// 内部协议，用于类型擦除 CommandHandler
private protocol AnyCommandHandler {
    var base: Any { get }
}

/// 包装 CommandHandler，实现类型擦除
private struct AnyCommandHandlerWrapper: AnyCommandHandler {
    let base: Any // 存储实际的 CommandHandler 实例

    init<C: Command, H: CommandHandler>(_ handler: H) where H.C == C {
        self.base = handler
    }
}

/// 内部协议，用于类型擦除 QueryHandler
private protocol AnyQueryHandler {
    var base: Any { get }
}

/// 包装 QueryHandler，实现类型擦除
private struct AnyQueryHandlerWrapper: AnyQueryHandler {
    let base: Any // 存储实际的 QueryHandler 实例

    init<Q: Query, R, H: QueryHandler>(_ handler: H) where H.Q == Q, H.R == R {
        self.base = handler
    }
}

