//
//  TopicCommands.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

// MARK: - 辅助领域类型导入 (这些类型应在 Core/Domain 目录下各自的文件中定义)
// 在实际项目中，您需要根据您的模块和 Swift Package 结构添加具体的 import 语句。
// 例如:
// import NotBadCoreDomainEntitiesContentSubject // 包含 Subject
// import NotBadCoreDomainEntitiesContentTopic // 包含 Topic (如果 TopicID 是其内部类型)
// import NotBadCoreApplicationCommands // 包含 Command 协议

/// 主题命令：创建主题
/// 用于在特定学科下创建一个新的学习主题。
/// 遵循 `Command` 协议。
struct CreateTopicCommand: Command {
    let name: String // 主题名称
    let subject: Subject // 所属学科
    let description: String? // 主题描述，可选

    // Hashable 和 Equatable 协议的自动实现
}

/// 主题命令：更新主题名称
/// 用于修改现有主题的名称。
/// 遵循 `Command` 协议。
struct UpdateTopicNameCommand: Command {
    let topicId: UUID // 要更新的主题ID
    let newName: String // 新的主题名称

    // Hashable 和 Equatable 协议的自动实现
}

/// 主题命令：更新主题描述
/// 用于修改现有主题的描述。
/// 遵循 `Command` 协议。
struct UpdateTopicDescriptionCommand: Command {
    let topicId: UUID // 要更新的主题ID
    let newDescription: String? // 新的主题描述，nil 表示清除

    // Hashable 和 Equatable 协议的自动实现
}

/// 主题命令：删除主题
/// 用于从系统中删除一个主题。
/// 遵循 `Command` 协议。
struct DeleteTopicCommand: Command {
    let topicId: UUID // 要删除的主题ID

    // Hashable 和 Equatable 协议的自动实现
}

