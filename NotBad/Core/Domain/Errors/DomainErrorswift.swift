//
//  DomainError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 领域错误基础协议
/// 所有在领域层定义的业务逻辑错误都应遵循此协议。
/// 它继承自 Swift 的 `Error` 协议，并增加了 `CustomStringConvertible` 和 `LocalizedError`，
/// 以便提供统一的错误描述和本地化支持。
protocol DomainError: Error, CustomStringConvertible, LocalizedError {
    // 您可以在这里定义所有领域错误共有的属性或方法。
    // 例如，一个错误码，或者一个更详细的错误上下文。
    // 目前，我们依赖于 `CustomStringConvertible` 和 `LocalizedError` 提供的描述。
}

