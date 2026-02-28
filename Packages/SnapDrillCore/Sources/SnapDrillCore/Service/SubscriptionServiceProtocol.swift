//
//  SubscriptionServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  订阅服务协议，抽象 StoreKit 2 的购买逻辑
//

import Foundation

// MARK: - 购买结果

/// 购买操作的结果
///
/// Result of a purchase operation.
public enum PurchaseResult: Sendable {
    /// 购买成功
    case success
    /// 用户取消
    case cancelled
    /// 购买待审核（如家长控制）
    case pending
    /// 购买失败
    case failed(Error)
}

// MARK: - 订阅服务协议

/// 订阅服务协议
///
/// 抽象 StoreKit 2 的核心购买交互，使 UI 和业务逻辑与具体实现解耦。
/// Abstracts StoreKit 2 purchase interactions to decouple UI/business logic from implementation.
@MainActor
public protocol SubscriptionServiceProtocol: Sendable {

    /// 当前订阅状态
    var subscriptionStatus: SubscriptionStatus { get }

    /// 可用的商品列表
    var availableProducts: [SubscriptionProduct] { get }

    /// 获取可用商品
    ///
    /// Fetches all available subscription products from App Store Connect.
    func fetchProducts() async throws

    /// 发起购买
    ///
    /// Initiates a purchase for the given product.
    /// - Parameter product: 要购买的商品
    /// - Returns: 购买结果
    func purchase(_ product: SubscriptionProduct) async throws -> PurchaseResult

    /// 恢复购买
    ///
    /// Restores previously purchased subscriptions.
    func restorePurchases() async throws

    /// 监听交易更新
    ///
    /// Starts listening for transaction updates (renewals, revocations, etc.).
    func startTransactionListener()
}
