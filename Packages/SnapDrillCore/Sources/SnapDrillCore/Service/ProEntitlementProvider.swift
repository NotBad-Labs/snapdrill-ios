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
public struct DefaultProEntitlementProvider: ProEntitlementProvider {

    public init() {}

    // TODO: #479 - Replace with StoreKit subscription status once Apple account access is unblocked.
    public var isProUser: Bool { false }
}
