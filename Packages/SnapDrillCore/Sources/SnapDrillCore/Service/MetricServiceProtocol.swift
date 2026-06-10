//
//  MetricServiceProtocol.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设备级遥测/诊断服务协议（MetricKit 包装）+ 中立 payload 快照 DTO。
//

import Foundation

/// 设备级遥测/诊断快照（中立 DTO）
///
/// 隔离 MetricKit 的 `MX*` 类型，使协议保持中立、可测（测试手造快照即可，无需构造不可控的真
/// `MXMetricPayload`），且作为 `Sendable` 值类型可安全跨后台线程边界传递（MetricKit 回调在后台线程触发）。
nonisolated public struct MetricPayloadSnapshot: Sendable, Equatable {

    /// payload 类型
    public enum Kind: String, Sendable {
        /// 性能/退出聚合（MXMetricPayload）
        case metric
        /// 崩溃/hang/异常诊断（MXDiagnosticPayload）
        case diagnostic
    }

    /// 快照类型
    public let kind: Kind
    /// 崩溃诊断数
    public let crashCount: Int
    /// 无响应（hang）诊断数
    public let hangCount: Int
    /// CPU 异常诊断数
    public let cpuExceptionCount: Int
    /// 磁盘写入异常诊断数
    public let diskWriteExceptionCount: Int
    /// `payload.jsonRepresentation()` 原始 JSON，供本地落盘取证；`nil` = 无 JSON（不落盘）
    public let jsonRepresentation: Data?
    /// 快照接收时间
    public let receivedAt: Date

    public init(
        kind: Kind,
        crashCount: Int = 0,
        hangCount: Int = 0,
        cpuExceptionCount: Int = 0,
        diskWriteExceptionCount: Int = 0,
        jsonRepresentation: Data? = nil,
        receivedAt: Date
    ) {
        self.kind = kind
        self.crashCount = crashCount
        self.hangCount = hangCount
        self.cpuExceptionCount = cpuExceptionCount
        self.diskWriteExceptionCount = diskWriteExceptionCount
        self.jsonRepresentation = jsonRepresentation
        self.receivedAt = receivedAt
    }

    /// 是否含需关注的诊断信号（崩溃/hang/CPU/磁盘异常任一 > 0）
    public var hasDiagnosticSignal: Bool {
        crashCount > 0 || hangCount > 0 || cpuExceptionCount > 0 || diskWriteExceptionCount > 0
    }
}

/// 设备级遥测/诊断服务协议（MetricKit 包装）
///
/// 订阅 Apple MetricKit 的聚合 payload（崩溃/hang/性能），本地 log + 落盘，关 RC-4 崩溃监控缺口。
/// 数据不出设备、无第三方 SDK、无需用户同意（Apple 已隐私聚合）——契合 ADR-005 D6=A 零采集/本地优先。
public protocol MetricServiceProtocol: Sendable {

    /// 注册 MetricKit subscriber 开始接收聚合 payload。
    ///
    /// 由 App 启动时（主线程 `.task`）调用一次；subscriber 须 app 级保活（经 `DependencyContainer.shared` 链）。
    func startMonitoring()

    /// 处理一个 payload 快照：本地 log（诊断级 `.error` / 性能级 `.info`）+ 落盘原始 JSON。
    ///
    /// 可测的纯逻辑入口——测试手造 `MetricPayloadSnapshot` 喂入，不依赖真 `MX*` payload。
    /// 标 `nonisolated`：MetricKit 回调在后台线程触发，handler 须后台线程安全。
    nonisolated func handle(_ snapshot: MetricPayloadSnapshot)
}
