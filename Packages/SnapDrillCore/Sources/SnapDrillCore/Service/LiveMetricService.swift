//
//  LiveMetricService.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  设备级遥测/诊断服务生产实现（MetricKit）。
//

import Foundation
import MetricKit

/// 设备级遥测/诊断服务生产实现（MetricKit）
///
/// 订阅 `MXMetricManager` 接收聚合 payload，本地 log + 落盘原始 JSON。数据不出设备、无需用户同意
/// （ADR-005 D6=A 零采集/本地优先），关 RC-4 崩溃监控缺口。
///
/// `@unchecked Sendable`：`hasStarted` 仅主线程 `startMonitoring` 触碰；后台 `didReceive` 回调只读
/// `nonisolated let` store、转发到 `nonisolated handle`。Store 自己串行化文件 IO，因为 MetricKit
/// 不保证回调顺序。
public final class LiveMetricService: NSObject, MetricServiceProtocol, MXMetricManagerSubscriber, @unchecked Sendable {

    /// `nil` 只用于显式的测试 log-only 模式；生产始终注入 app-owned store。
    private nonisolated let store: MetricDiagnosticsStore?
    /// 防重复注册守卫（仅主线程 `startMonitoring` 触碰）
    private var hasStarted = false

    init(store: MetricDiagnosticsStore?) {
        self.store = store
        super.init()
    }

    // MARK: - MetricServiceProtocol

    public func startMonitoring() {
        guard !hasStarted else { return }
        hasStarted = true
        MXMetricManager.shared.add(self)
        SnapDrillLogger.generic.info("MetricKit 订阅已注册")
    }

    public nonisolated func handle(_ snapshot: MetricPayloadSnapshot) {
        switch snapshot.kind {
        case .diagnostic where snapshot.hasDiagnosticSignal:
            SnapDrillLogger.generic.error(
                "MetricKit 诊断 crash=\(snapshot.crashCount) hang=\(snapshot.hangCount) cpu=\(snapshot.cpuExceptionCount) disk=\(snapshot.diskWriteExceptionCount)"
            )
        case .diagnostic:
            SnapDrillLogger.generic.info("MetricKit 诊断 payload（无异常信号）")
        case .metric:
            SnapDrillLogger.generic.info("MetricKit 性能 payload 已接收")
        }
        persist(snapshot)
    }

    // MARK: - MXMetricManagerSubscriber（后台回调，数组版现代签名）

    public nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            handle(MetricPayloadSnapshot(
                kind: .metric,
                jsonRepresentation: payload.jsonRepresentation(),
                receivedAt: Date()
            ))
        }
    }

    public nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            handle(MetricPayloadSnapshot(
                kind: .diagnostic,
                crashCount: payload.crashDiagnostics?.count ?? 0,
                hangCount: payload.hangDiagnostics?.count ?? 0,
                cpuExceptionCount: payload.cpuExceptionDiagnostics?.count ?? 0,
                diskWriteExceptionCount: payload.diskWriteExceptionDiagnostics?.count ?? 0,
                jsonRepresentation: payload.jsonRepresentation(),
                receivedAt: Date()
            ))
        }
    }

    // MARK: - 落盘 + 轮转

    private nonisolated func persist(_ snapshot: MetricPayloadSnapshot) {
        guard let store, let json = snapshot.jsonRepresentation else { return }
        do {
            try store.persist(json, kind: snapshot.kind, receivedAt: snapshot.receivedAt)
        } catch {
            SnapDrillLogger.generic.error(
                "MetricKit payload persistence failed: \(String(describing: error))"
            )
        }
    }
}
