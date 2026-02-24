//
//  AnalyticsService.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  统计服务协议定义，遵循依赖倒置原则。
//

import Foundation

/// 统计分析服务协议 (DIP 抽象层)
///
/// 遵循依赖倒置原则，上层业务模块不需要知道具体的统计实现（Flurry, Firebase, PostHog等）。
public protocol AnalyticsService: Sendable {
    /// 记录事件
    /// - Parameters:
    ///   - name: 事件名称 (e.g. "capture_success")
    ///   - properties: 附加属性 (e.g. ["source": "camera"])
    func logEvent(_ name: String, properties: [String: String]?)
}
