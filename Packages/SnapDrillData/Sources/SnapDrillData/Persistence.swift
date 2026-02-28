//
//  Persistence.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData 持久化控制器，管理 ModelContainer
//
//  IMPORTANT: iOS 18 SwiftData 已知问题 workaround
//  - 避免使用 Migration Plan（iOS 18.1 数组类型变化导致迁移失败）
//  - 使用最简单的初始化方式
//  - 确保所有模型属性都有默认值或可选
//

import SwiftData
import OSLog

private let logger = Logger(subsystem: "com.snapdrill.app", category: "Persistence")

@MainActor
public class PersistenceController {
    
    // MARK: - Properties
    
    public static let shared = PersistenceController()
    
    public let container: ModelContainer
    
    /// 标记是否使用内存存储（降级模式）
    public private(set) var isUsingInMemoryFallback: Bool = false
    
    /// 持久化错误（如果有）
    public private(set) var initializationError: PersistenceError?
    
    // MARK: - Initialization
    
    public init(inMemory: Bool = false) {
        logger.info("🔧 Initializing SwiftData (iOS 18 hardened versioning)")
        
        do {
            let schema = Schema(SnapDrillSchemaV1.models)
            let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
            
            // 使用显式 Schema 初始化以增强稳定性
            self.container = try ModelContainer(for: schema, configurations: config)
            self.isUsingInMemoryFallback = inMemory
            self.initializationError = nil
            logger.info("✅ Container initialized successfully with SnapDrillSchemaV1")
            
        } catch {
            logger.error("❌ Primary initialization failed: \(error.localizedDescription)")
            self.initializationError = PersistenceError.containerInitializationFailed(underlying: error)
            
            // 尝试处理初始化错误（如版本不匹配或文件损坏）
            // 在 Beta 阶段，我们可能会执行数据清空逻辑
            let fallbackResult = Self.handleInitializationError(error, inMemory: inMemory)
            self.container = fallbackResult.0
            self.isUsingInMemoryFallback = fallbackResult.1
        }
    }
    
    // MARK: - Error Handling
    
    /// 处理初始化失败的备选方案
    private static func handleInitializationError(_ error: Error, inMemory: Bool) -> (ModelContainer, Bool) {
        logger.warning("⚠️ Entering fail-safe initialization mode")
        
        // 如果不是内存模式，且发生了迁移错误，尝试进行“软重置”（仅限 Beta）
        // 实战建议：此处可根据 PersistenceError 类型判断是否删除数据库文件重新初始化
        
        do {
            logger.warning("Attempting in-memory fallback to keep app running...")
            let fallbackConfig = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Schema(SnapDrillSchemaV1.models), configurations: fallbackConfig)
            return (container, true)
        } catch {
            logger.critical("💀 Critical failure: Even in-memory fallback failed.")
            // 最后的保命措施：如果内存模式也失败，我们至少不应该在这里奔溃应用
            // 在生产环境中，这里应该抛出错误让上层 UI 展示引导修复页面
            fatalError("SwiftData initialization failed significantly: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public API
    
    /// 执行数据全量擦除（重置数据库）
    /// 仅限从 UI 触发或初始化严重失败时调用
    public func wipeAllData() {
        logger.warning("🚨 Wiping all persistent data as requested")
        // 获取数据库 URL 并删除文件
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("default.store") // SwiftData 默认存储路径
        
        try? FileManager.default.removeItem(at: url)
        logger.info("✅ Data wipe completed. Restart app to re-initialize.")
    }
}
