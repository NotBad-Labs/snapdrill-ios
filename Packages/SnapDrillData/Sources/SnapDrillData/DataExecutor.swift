//
//  DataExecutor.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  拥有 ModelContainer 的 actor，将容器创建从 MainActor 移到 actor 专属执行器，
//  根除 #599 死锁（MainActor + ModelContainer.init XPC 回调 ABBA）。
//

import Foundation
import SwiftData
import SnapDrillCore

/// 拥有 ModelContainer 的 actor。
///
/// ## 并发安全模型
/// - `container` 用 `nonisolated` 声明：`ModelContainer` 在 Xcode 26.4 中已标注 Sendable，
///   允许从 actor 外部同步访问。Repository 在 MainActor 上通过 `executor.container.mainContext`
///   获取上下文，不走跨 actor 异步路径，ViewModel 和 Repository API 无需改为 async。
///
/// ## 死锁消除
/// - `createOffMainActor()` 工厂方法在 `Task.detached` 中调用 `init`，
///   `ModelContainer(for:migrationPlan:configurations:)` 不在 MainActor 上执行，
///   XPC 回调无需等待 MainActor，消除 ABBA 死锁。
/// - 从 MainActor 直接调用 `init` 时（如 SwiftUI Preview），因无 XCTest runner
///   无死锁风险，为便利性提供。
///
/// ## nonisolated(unsafe) 使用正当化
/// - `ModelContainer` 是 Apple SDK 类型，尚未审计 Sendable
/// - init 后 `let` 只读，Apple 保证 `container.mainContext` 线程安全
/// - nonisolated(unsafe) 仅限 Apple SDK 类型 + 只读访问（无可变共享状态，线程安全）
public actor DataExecutor {

    // MARK: - Properties

    /// SwiftData 容器。init 后只读。
    /// nonisolated：ModelContainer 为 Sendable，允许从 actor 外部同步访问。
    nonisolated public let container: ModelContainer

    /// 是否使用内存降级存储
    public private(set) var isUsingInMemoryFallback: Bool = false

    /// 初始化错误（若有）
    public private(set) var initializationError: PersistenceError?

    /// 磁盘 store 隔离重建事件（若本次启动发生过）。
    public private(set) var storeRecoveryEvent: StoreRecoveryEvent?

    // MARK: - Initialization

    /// 创建 DataExecutor，初始化 ModelContainer。
    ///
    /// 注意：actor init 在当前调用方的执行器上运行。
    /// 从 MainActor 调用时仍在 MainActor 上执行。
    /// 如需确保在 MainActor 之外执行，使用 ``createOffMainActor(inMemory:storeURL:)``。
    ///
    /// - Parameters:
    ///   - inMemory: 为 `true` 时使用内存存储（测试 / Preview）
    ///   - storeURL: 数据库文件路径。传 nil 使用系统默认路径。
    ///     Profile 模式下传入 `profiles/<id>/default.store`。
    public init(inMemory: Bool = false, storeURL: URL? = nil) {
        SnapDrillLogger.data.info("🔧 DataExecutor: 初始化 ModelContainer")

        do {
            self.container = try Self.makeContainer(inMemory: inMemory, storeURL: storeURL)
            self.isUsingInMemoryFallback = false
            self.initializationError = nil
            SnapDrillLogger.data.info("✅ DataExecutor: 容器创建成功")
        } catch {
            SnapDrillLogger.data.error("❌ DataExecutor: 初始化失败: \(error.localizedDescription)")

            if !inMemory, let storeURL, let recovered = Self.recoverDiskContainer(
                at: storeURL,
                after: error
            ) {
                self.container = recovered.container
                self.isUsingInMemoryFallback = false
                self.initializationError = nil
                self.storeRecoveryEvent = recovered.event
                return
            }

            self.initializationError = PersistenceError.containerInitializationFailed(underlying: error)

            let (fallbackContainer, usedFallback) = Self.fallbackContainer()
            self.container = fallbackContainer
            self.isUsingInMemoryFallback = usedFallback
        }
    }

    /// 用已存在的 ModelContainer 构建执行器
    /// - Parameter container: 已创建好的 ModelContainer
    public init(container: ModelContainer) {
        self.container = container
    }

    /// 打开已由 LocalLibrary startup 选定的生产 store。
    ///
    /// 与 legacy Profile 路径不同，此入口严格 fail closed：打开失败直接抛错，不隔离原文件、
    /// 不发布空 store，也不降级到内存容器。上层必须进入 LocalLibrary 恢复协调。
    private init(strictStoreURL: URL) throws {
        do {
            self.container = try Self.makeContainer(inMemory: false, storeURL: strictStoreURL)
        } catch {
            throw PersistenceError.containerInitializationFailed(underlying: error)
        }
    }

    // MARK: - Factory

    /// 在非 MainActor 执行器上创建 DataExecutor，避免 #599 死锁。
    ///
    /// 使用 `Task.detached` 确保 `ModelContainer.init()` 在全局并发执行器上运行。
    /// 调用方 await 恢复后在原隔离域继续执行。
    ///
    /// - Parameters:
    ///   - inMemory: 使用内存存储
    ///   - storeURL: 数据库文件路径
    /// - Returns: 已初始化的 DataExecutor
    public static func createOffMainActor(
        inMemory: Bool = false,
        storeURL: URL? = nil
    ) async -> DataExecutor {
        await Task.detached {
            DataExecutor(inMemory: inMemory, storeURL: storeURL)
        }.value
    }

    /// 在非 MainActor 执行器上严格打开 LocalLibrary store。
    ///
    /// 此入口只供唯一生产 LocalLibrary runtime 使用。失败不改变 store 文件集，也不创建
    /// 第二个 runtime；调用方负责把错误映射为启动阻塞或 storeRecovery。
    public static func openLocalLibraryStore(
        at storeURL: URL
    ) async throws -> DataExecutor {
        try await Task.detached {
            try DataExecutor(strictStoreURL: storeURL)
        }.value
    }

    // MARK: - Private Helpers

    private static func makeContainer(inMemory: Bool = false, storeURL: URL? = nil) throws -> ModelContainer {
        let config: ModelConfiguration
        if inMemory {
            config = ModelConfiguration(isStoredInMemoryOnly: true)
        } else if let storeURL {
            config = ModelConfiguration(url: storeURL, cloudKitDatabase: .none)
        } else {
            config = ModelConfiguration(cloudKitDatabase: .none)
        }

        return try ModelContainer(
            for: Schema(SnapDrillSchemaV1.models),
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: config
        )
    }

    private struct DiskRecoveryResult {
        let container: ModelContainer
        let event: StoreRecoveryEvent?
    }

    private static func recoverDiskContainer(at storeURL: URL, after originalError: Error) -> DiskRecoveryResult? {
        SnapDrillLogger.data.warning(
            "⚠️ DataExecutor: 磁盘 store 打开失败，准备重试: \(originalError.localizedDescription)"
        )

        do {
            let container = try makeContainer(inMemory: false, storeURL: storeURL)
            SnapDrillLogger.data.warning("⚠️ DataExecutor: 磁盘 store 重试打开成功: \(storeURL.lastPathComponent)")
            return DiskRecoveryResult(container: container, event: nil)
        } catch {
            SnapDrillLogger.data.error("❌ DataExecutor: 磁盘 store 重试仍失败: \(error.localizedDescription)")
            return isolateAndRebuildDiskContainer(at: storeURL, originalError: originalError, retryError: error)
        }
    }

    private static func isolateAndRebuildDiskContainer(
        at storeURL: URL,
        originalError: Error,
        retryError: Error
    ) -> DiskRecoveryResult? {
        do {
            let isolationDirectory = try isolateStoreFiles(at: storeURL)
            let container = try makeContainer(inMemory: false, storeURL: storeURL)
            let event = StoreRecoveryEvent(
                storeURL: storeURL,
                isolationDirectoryURL: isolationDirectory,
                originalErrorDescription: originalError.localizedDescription,
                retryErrorDescription: retryError.localizedDescription
            )
            SnapDrillLogger.data.warning(
                "⚠️ DataExecutor: 已隔离并重建磁盘 store: \(isolationDirectory.path)"
            )
            return DiskRecoveryResult(container: container, event: event)
        } catch {
            SnapDrillLogger.data.error("❌ DataExecutor: 磁盘 store 隔离重建失败: \(error.localizedDescription)")
            return nil
        }
    }

    private static func isolateStoreFiles(at storeURL: URL) throws -> URL {
        let manager = FileManager.default
        let profileDirectory = storeURL.deletingLastPathComponent()
        let timestamp = storeIsolationTimestamp()
        let isolationDirectory = try uniqueIsolationDirectory(
            under: ProfileVault.corruptedStoreIsolationDirectory(
                forProfileDirectory: profileDirectory,
                timestamp: timestamp
            ),
            fileManager: manager
        )

        try manager.createDirectory(at: isolationDirectory, withIntermediateDirectories: true)
        for url in storeFileSet(for: storeURL) where manager.fileExists(atPath: url.path) {
            try manager.moveItem(at: url, to: isolationDirectory.appendingPathComponent(url.lastPathComponent))
        }

        return isolationDirectory
    }

    private static func uniqueIsolationDirectory(under baseURL: URL, fileManager: FileManager) throws -> URL {
        var candidate = baseURL
        var suffix = 1
        while fileManager.fileExists(atPath: candidate.path) {
            candidate = baseURL.deletingLastPathComponent()
                .appendingPathComponent("\(baseURL.lastPathComponent)-\(suffix)", isDirectory: true)
            suffix += 1
        }
        return candidate
    }

    private static func storeIsolationTimestamp(date: Date = Date()) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: date)
            .replacingOccurrences(of: ":", with: "-")
    }

    private static func storeFileSet(for storeURL: URL) -> [URL] {
        [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-wal"),
            URL(fileURLWithPath: storeURL.path + "-shm")
        ]
    }

    /// 内存降级容器创建
    private static func fallbackContainer() -> (ModelContainer, Bool) {
        SnapDrillLogger.data.warning("⚠️ DataExecutor: 降级到内存存储")
        do {
            let container = try makeContainer(inMemory: true)
            return (container, true)
        } catch {
            SnapDrillLogger.data.critical("💀 DataExecutor: 降级也失败: \(error.localizedDescription)")
            fatalError("SwiftData 初始化完全失败: \(error.localizedDescription)")
        }
    }
}
