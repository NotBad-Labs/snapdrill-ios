//
//  SubscriptionServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  订阅服务测试替身，首发阶段模拟全功能解锁状态。
//

import Foundation

// MARK: - Mock 订阅服务

/// 订阅服务 Mock 实现
///
/// 用于单元测试和 SwiftUI Preview，模拟不同的订阅状态。
/// Mock implementation for unit testing and SwiftUI previews.
@MainActor
public final class SubscriptionServiceMock: SubscriptionServiceProtocol {

    // MARK: - Properties

    public private(set) var subscriptionStatus: SubscriptionStatus
    public private(set) var availableProducts: [SubscriptionProduct]

    // MARK: - 测试追踪

    /// 追踪 `fetchProducts()` 被调用的次数
    public private(set) var fetchProductsCallCount = 0

    /// 追踪 `purchase(_:)` 被调用的次数
    public private(set) var purchaseCallCount = 0

    /// 追踪 `restorePurchases()` 被调用的次数
    public private(set) var restoreCallCount = 0

    /// 模拟购买结果（可在测试中注入）
    public var simulatedPurchaseResult: PurchaseResult = .success

    /// 模拟抛出的错误（可在测试中注入）
    public var simulatedError: Error?

    // MARK: - Initialization

    public init(
        status: SubscriptionStatus = .free,
        products: [SubscriptionProduct] = SubscriptionServiceMock.defaultProducts
    ) {
        self.subscriptionStatus = status
        self.availableProducts = products
    }

    // MARK: - SubscriptionServiceProtocol

    public func fetchProducts() async throws {
        fetchProductsCallCount += 1
        if let error = simulatedError {
            throw error
        }
    }

    public func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult {
        purchaseCallCount += 1
        if let error = simulatedError {
            throw error
        }
        if case .success = simulatedPurchaseResult {
            subscriptionStatus = .premium
        }
        return simulatedPurchaseResult
    }

    public func restorePurchases() async throws {
        restoreCallCount += 1
        if let error = simulatedError {
            throw error
        }
    }

    public func startTransactionListener() {
        // Mock 实现，不执行任何操作
    }

    // MARK: - 测试辅助

    /// 手动设置订阅状态（便于测试不同场景）
    public func setStatus(_ status: SubscriptionStatus) {
        self.subscriptionStatus = status
    }

    /// 默认测试商品
    public static let defaultProducts: [SubscriptionProduct] = [
        SubscriptionProduct(
            id: "com.snapdrill.app.monthly",
            displayName: "月度会员",
            description: "解锁所有高级功能",
            displayPrice: "$4.99/月",
            period: .monthly
        ),
        SubscriptionProduct(
            id: "com.snapdrill.app.yearly",
            displayName: "年度会员",
            description: "解锁所有高级功能，年付更优惠",
            displayPrice: "$29.99/年",
            period: .yearly
        )
    ]
}
