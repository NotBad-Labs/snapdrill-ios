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
/// `nonisolated let` 配置、转发到 `nonisolated handle`，其文件 IO（落盘 + 轮转）由 `ioLock` 串行化，
/// 防并发回调交错（MetricKit 不保证串行投递）。
public final class LiveMetricService: NSObject, MetricServiceProtocol, MXMetricManagerSubscriber, @unchecked Sendable {

    /// 落盘目录（App Group 容器下 metrickit/）；`nil` = 降级为仅 log，不落盘
    private nonisolated let storageDirectory: URL?
    /// 落盘保留文件数上限（轮转，防无界增长）
    private nonisolated let maxStoredFiles: Int
    /// 串行化落盘 + 轮转的文件 IO，防并发回调交错（MetricKit 不保证串行投递）
    private nonisolated let ioLock = NSLock()
    /// 防重复注册守卫（仅主线程 `startMonitoring` 触碰）
    private var hasStarted = false

    /// 测试用：直接注入落盘目录。
    public init(storageDirectory: URL?, maxStoredFiles: Int = 30) {
        self.storageDirectory = storageDirectory
        self.maxStoredFiles = maxStoredFiles
        super.init()
    }

    /// 生产用：落盘到 App Group 容器的 metrickit/ 子目录。
    public convenience init(appGroupIdentifier: String = "group.com.snapdrill.global", maxStoredFiles: Int = 30) {
        let directory = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)?
            .appendingPathComponent("metrickit", isDirectory: true)
        self.init(storageDirectory: directory, maxStoredFiles: maxStoredFiles)
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
        guard let directory = storageDirectory, let json = snapshot.jsonRepresentation else { return }
        ioLock.withLock {
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                let stamp = ISO8601DateFormatter().string(from: snapshot.receivedAt)
                    .replacingOccurrences(of: ":", with: "-")
                // 唯一后缀：同一秒内同类型多 payload 不互相覆盖（didReceive 数组循环用同一 Date()）
                let unique = UUID().uuidString.prefix(8)
                let fileURL = directory.appendingPathComponent("\(snapshot.kind.rawValue)-\(stamp)-\(unique).json")
                try json.write(to: fileURL, options: .atomic)
                rotate(in: directory)
            } catch {
                SnapDrillLogger.generic.error("MetricKit payload 落盘失败: \(error.localizedDescription)")
            }
        }
    }

    /// 保留最近 `maxStoredFiles` 个文件，按创建时间删最旧。
    private nonisolated func rotate(in directory: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ), files.count > maxStoredFiles else { return }
        let sorted = files.sorted { lhs, rhs in
            let lDate = (try? lhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            let rDate = (try? rhs.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
            return lDate < rDate
        }
        for fileURL in sorted.prefix(files.count - maxStoredFiles) {
            do {
                try FileManager.default.removeItem(at: fileURL)
            } catch {
                SnapDrillLogger.generic.error("MetricKit 轮转删除失败: \(error.localizedDescription)")
            }
        }
    }
}
