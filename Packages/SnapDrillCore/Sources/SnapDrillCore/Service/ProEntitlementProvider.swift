//
//  ProEntitlementProvider.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright (c) 2026 NotBad Labs L.L.C. All rights reserved.
//
//  Pro entitlement provider.
//

import Foundation

/// Provides the current user's Pro entitlement status.
public protocol ProEntitlementProvider {
    var isProUser: Bool { get }
}

/// 默认 Pro 权益提供者：Composition Root（`LiveServiceContainer`）的合法默认装配，
/// #479 StoreKit 落地前恒返回 false。
///
/// 约束（S-D4-001）：Feature 层**不得**直接实例化此类型，应经
/// `@Environment(\.services).proEntitlement` 注入；该约束由架构评审保证。
/// 不用 `@available(*, deprecated)` 标注——本类型并非「废弃待移除」，而是 #479 前的现役占位，
/// 对其唯一合法调用点（`LiveServiceContainer` 默认装配）报弃用警告会自相矛盾。
public struct DefaultProEntitlementProvider: ProEntitlementProvider {

    public init() {}

    // TODO: #479 - Replace with StoreKit subscription status once Apple account access is unblocked.
    public var isProUser: Bool { false }
}

/// Mock Pro entitlement provider (测试 / Preview)。`isProUser` 可注入。
public struct MockProEntitlementProvider: ProEntitlementProvider {

    public let isProUser: Bool

    public init(isProUser: Bool = false) {
        self.isProUser = isProUser
    }
}
