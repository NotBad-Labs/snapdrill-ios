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

/// Default Pro entitlement provider.
@available(*, deprecated, message: "通过 @Environment(\\.services).proEntitlement 注入，避免散落默认实现（S-D4-001）")
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
