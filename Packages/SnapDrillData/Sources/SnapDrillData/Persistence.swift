//
//  Persistence.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData 持久化控制器，管理 ModelContainer 生命周期与 Schema 迁移。
//

import Foundation
import SwiftData
import SnapDrillCore

public final class PersistenceController {

    // MARK: - Properties

    /// 共享持久化控制器实例（兼容旧代码，Multi-Profile 模式下由 ProfileManager 管理）
    public static let shared = PersistenceController()

    /// SwiftData ModelContainer，用于创建 ModelContext
    public let container: ModelContainer

    /// 标记是否使用内存存储（降级模式）
    public private(set) var isUsingInMemoryFallback: Bool = false

    /// 持久化错误（如果有）
    public private(set) var initializationError: PersistenceError?

    // MARK: - Initialization

    /// 创建持久化控制器
    /// - Parameters:
    ///   - inMemory: 为 `true` 时使用内存存储（用于测试 / Preview），默认使用磁盘持久化
    ///   - storeURL: 指定数据库文件路径。传 nil 使用系统默认路径（兼容旧代码）。
    ///     Profile 模式下传入 `profiles/<id>/default.store`。
    public init(inMemory: Bool = false, storeURL: URL? = nil) {
        SnapDrillLogger.data.info("🔧 Initializing SwiftData with SnapDrillMigrationPlan")

        do {
            let config: ModelConfiguration
            if inMemory {
                config = ModelConfiguration(isStoredInMemoryOnly: true)
            } else if let storeURL {
                config = ModelConfiguration(url: storeURL)
            } else {
                config = ModelConfiguration()
            }
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
            SnapDrillLogger.data.critical("💀 Critical: In-memory ModelContainer also failed. Error: \(error.localizedDescription)")
            fatalError("SwiftData initialization failed significantly: \(error.localizedDescription)")
        }
    }
}
