//
//  Query.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//


//
//  Query.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 查询协议
/// 所有表示从应用状态中获取数据（不修改状态）的操作都应遵循此协议。
/// 查询是纯粹的数据结构，只包含获取数据所需的所有输入参数，不包含任何业务逻辑。
///
/// 遵循 `Sendable` 协议，以支持在并发环境中的安全传递。
/// 遵循 `Hashable` 和 `Equatable` 协议，以便在需要时作为字典的键或在集合中进行比较。
protocol Query: Hashable, Sendable {
    // 查询本身通常不需要额外的属性或方法，
    // 它们的具体数据由遵循此协议的结构体定义。
    // 例如：
    // var userId: UserID { get }
    // var questionId: QuestionID { get }
}
