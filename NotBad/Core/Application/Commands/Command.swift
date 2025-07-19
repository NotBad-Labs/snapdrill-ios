//
//  Command.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  Command.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 命令协议
/// 所有表示对应用状态进行修改的操作都应遵循此协议。
/// 命令是纯粹的数据结构，只包含执行操作所需的所有输入参数，不包含任何业务逻辑。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全传递。
/// 遵循 `Hashable` 和 `Equatable` 协议，以便在需要时作为字典的键或在集合中进行比较。
protocol Command: Hashable, Sendable {
    // 命令本身通常不需要额外的属性或方法，
    // 它们的具体数据由遵循此协议的结构体定义。
    // 例如：
    // var userId: UserID { get }
    // var timestamp: Date { get }
}
