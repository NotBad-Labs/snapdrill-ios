//
//  Persistence.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData 持久化控制器，管理 ModelContainer 生命周期与 Schema 迁移。
//

import SwiftData
import SnapDrillCore

@MainActor
public final class PersistenceController {

    // MARK: - Properties

    /// 共享持久化控制器实例（生产环境使用磁盘存储）
    public static let shared = PersistenceController()

    /// SwiftData ModelContainer，用于创建 ModelContext
    public let container: ModelContainer

    /// 标记是否使用内存存储（降级模式）
    public private(set) var isUsingInMemoryFallback: Bool = false

    /// 持久化错误（如果有）
    public private(set) var initializationError: PersistenceError?

    // MARK: - Initialization

    /// 创建持久化控制器
    /// - Parameter inMemory: 为 `true` 时使用内存存储（用于测试 / Preview），默认使用磁盘持久化
    public init(inMemory: Bool = false) {
        SnapDrillLogger.data.info("🔧 Initializing SwiftData with SnapDrillMigrationPlan")

        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            self.container = try ModelContainer(
                for: Schema(SnapDrillSchemaV4.models),
                migrationPlan: SnapDrillMigrationPlan.self,
                configurations: config
            )
            self.isUsingInMemoryFallback = false
            self.initializationError = nil
            SnapDrillLogger.data.info("✅ Container initialized successfully with SnapDrillSchemaV4")

        } catch {
            SnapDrillLogger.data.error("❌ Primary initialization failed: \(error.localizedDescription)")
            self.initializationError = PersistenceError.containerInitializationFailed(underlying: error)

            let fallbackResult = Self.handleInitializationError(error, inMemory: inMemory)
            self.container = fallbackResult.0
            self.isUsingInMemoryFallback = fallbackResult.1
        }
    }

    // MARK: - Error Handling

    /// 处理初始化失败的备选方案
    private static func handleInitializationError(_ error: Error, inMemory: Bool) -> (ModelContainer, Bool) {
        SnapDrillLogger.data.warning("⚠️ Entering fail-safe initialization mode")

        do {
            SnapDrillLogger.data.warning("Attempting in-memory fallback to keep app running...")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Schema(SnapDrillSchemaV4.models), configurations: fallbackConfig)
            return (container, true)
        } catch {
            // 内存模式的 ModelContainer 创建失败：此属于不可恢复的系统级错误。
            // 内存模式不依赖磁盘，若仍失败说明 SwiftData/系统层存在根本性问题。
            // 此时无法提供任何 ModelContext，继续运行只会产生更难调试的崩溃，
            // 直接 fatalError 以保证 Crash Report 能精确定位问题根因。
            SnapDrillLogger.data.critical("💀 Critical: In-memory ModelContainer also failed. Error: \(error.localizedDescription)")
            fatalError("SwiftData initialization failed significantly: \(error.localizedDescription)")
        }
    }
}
