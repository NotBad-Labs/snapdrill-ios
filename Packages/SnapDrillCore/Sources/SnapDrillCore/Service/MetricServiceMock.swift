//
//  MetricServiceMock.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  遥测诊断服务 Mock 实现，用于单元测试和 SwiftUI Preview。
//

import Foundation

/// 遥测诊断服务 Mock 实现，用于单元测试
///
/// 记录 `handle` 收到的快照与 `startMonitoring` 调用次数。`handle` 在协议中是 `nonisolated`
/// （后台回调），故内部可变状态用 `NSLock` 保护、类标 `@unchecked Sendable`。
public final class MetricServiceMock: MetricServiceProtocol, @unchecked Sendable {

    private let lock = NSLock()
    nonisolated(unsafe) private var storedSnapshots: [MetricPayloadSnapshot] = []
    nonisolated(unsafe) private var storedStartCount = 0

    public init() {}

    // MARK: - 记录读取（lock 保护）

    public nonisolated var receivedSnapshots: [MetricPayloadSnapshot] {
        lock.withLock { storedSnapshots }
    }

    public nonisolated var startMonitoringCallCount: Int {
        lock.withLock { storedStartCount }
    }

    // MARK: - MetricServiceProtocol

    public nonisolated func startMonitoring() {
        lock.withLock { storedStartCount += 1 }
    }

    public nonisolated func handle(_ snapshot: MetricPayloadSnapshot) {
        lock.withLock { storedSnapshots.append(snapshot) }
    }

    // MARK: - 测试辅助

    public nonisolated func reset() {
        lock.withLock {
            storedSnapshots.removeAll()
            storedStartCount = 0
        }
    }
}
