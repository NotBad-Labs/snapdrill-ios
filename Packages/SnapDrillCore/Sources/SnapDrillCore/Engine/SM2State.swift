//
//  SM2State.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SM-2 算法所需的调度状态值类型，解耦算法与具体实体。
//

import Foundation

/// SM-2 算法输入/输出状态
///
/// 纯值类型，不依赖任何实体模型。
/// `ReviewScheduler` 通过此类型计算下次复习时间，
/// 调用方负责将结果写回具体的 `@Model` 或领域对象。
public struct SM2State: Sendable {

    /// 难度因子（Ease Factor），初始值 2.5，最小 1.3
    public var easeFactor: Double

    /// 当前复习间隔（天数）
    public var interval: Int

    /// 连续正确复习次数
    public var repetitions: Int

    /// 下次复习时间
    public var nextReviewAt: Date?

    /// 上次复习时间
    public var lastReviewedAt: Date?

    /// 创建 SM-2 状态
    /// - Parameters:
    ///   - easeFactor: 难度因子，初始值 2.5，最小 1.3
    ///   - interval: 当前复习间隔（天数），初始为 0
    ///   - repetitions: 连续正确次数，初始为 0
    ///   - nextReviewAt: 下次复习时间，初始为 nil
    ///   - lastReviewedAt: 上次复习时间，初始为 nil
    public init(
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        nextReviewAt: Date? = nil,
        lastReviewedAt: Date? = nil
    ) {
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.nextReviewAt = nextReviewAt
        self.lastReviewedAt = lastReviewedAt
    }
}
