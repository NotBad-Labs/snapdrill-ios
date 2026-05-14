//
//  ProfileScope.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Profile 隔离作用域通行证。
//

import Foundation

/// Profile 隔离作用域
///
/// 所有依赖 Profile 数据隔离边界的服务应要求调用方传入此类型。
/// Profile 数据隔离的编译期通行证。所有依赖 Profile 隔离边界的服务应要求调用方传入此类型。
nonisolated public struct ProfileScope: Identifiable, Sendable {
    /// Profile 唯一标识符（同时作为隔离 store 的身份）
    public let id: UUID

    /// Profile 名称（仅用于日志和调试）
    public let name: String

    public init(id: UUID, name: String) {
        self.id = id
        self.name = name
    }
}
