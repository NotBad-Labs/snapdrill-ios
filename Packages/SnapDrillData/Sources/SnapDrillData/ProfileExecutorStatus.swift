//
//  ProfileExecutorStatus.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

/// ProfileManager 从 DataExecutor 同步到 SwiftUI 可观察状态的轻量快照。
struct ProfileExecutorStatus {
    static let healthy = ProfileExecutorStatus(isUsingInMemoryFallback: false, storeRecoveryEvent: nil)

    let isUsingInMemoryFallback: Bool
    let storeRecoveryEvent: StoreRecoveryEvent?

    init(isUsingInMemoryFallback: Bool, storeRecoveryEvent: StoreRecoveryEvent?) {
        self.isUsingInMemoryFallback = isUsingInMemoryFallback
        self.storeRecoveryEvent = storeRecoveryEvent
    }

    init(executor: DataExecutor) async {
        self.isUsingInMemoryFallback = await executor.isUsingInMemoryFallback
        self.storeRecoveryEvent = await executor.storeRecoveryEvent
    }
}
