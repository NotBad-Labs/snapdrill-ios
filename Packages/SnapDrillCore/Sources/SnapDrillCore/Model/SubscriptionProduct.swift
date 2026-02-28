//
//  SubscriptionProduct.swift
//  SnapDrillCore
//
//  Created by NotBad Labs on 2026/02/24.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  订阅商品模型定义
//

import Foundation

// MARK: - 订阅商品模型

/// 订阅商品信息
///
/// 封装 StoreKit 商品的关键属性，解耦 UI 层与 StoreKit 框架。
/// Wraps key StoreKit product attributes to decouple UI from the StoreKit framework.
public struct SubscriptionProduct: Sendable, Identifiable, Hashable {

    // MARK: - Properties

    /// 商品唯一标识符（对应 App Store Connect 中的 Product ID）
    public let id: String

    /// 商品显示名称
    public let displayName: String

    /// 商品描述
    public let description: String

    /// 格式化后的价格字符串（如 "$4.99/月"）
    public let displayPrice: String

    /// 订阅周期
    public let period: SubscriptionPeriod

    // MARK: - Initialization

    public init(
        id: String,
        displayName: String,
        description: String,
        displayPrice: String,
        period: SubscriptionPeriod
    ) {
        self.id = id
        self.displayName = displayName
        self.description = description
        self.displayPrice = displayPrice
        self.period = period
    }
}

// MARK: - 订阅周期

/// 订阅周期枚举
///
/// Subscription billing period.
public enum SubscriptionPeriod: String, Sendable, Codable {
    /// 月度订阅
    case monthly
    /// 年度订阅
    case yearly
    /// 终身买断
    case lifetime
}
