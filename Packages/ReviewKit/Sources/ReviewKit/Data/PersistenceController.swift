//
//  PersistenceController.swift
//  ReviewKit
//
//  统一的数据持久化控制器
//
//  关键：使用 App Groups 共享目录，让 Widget 能访问主 App 数据
//

import SwiftData
import Foundation
import os.log

private let logger = Logger(subsystem: "com.notbad.reviewkit", category: "Persistence")

// MARK: - App Group 配置

/// App Group 标识符
///
/// 必须在 Xcode 中为 NotBad 和 NotBadWidget 两个 Target 都启用此 App Group
public let appGroupIdentifier = "group.com.notbad.shared"

// MARK: - PersistenceController

/// 持久化控制器
///
/// 提供 App 和 Widget 共享的 ModelContainer。
///
/// ## 使用方法
///
/// ```swift
/// // 在 App 中
/// import ReviewKit
///
/// WindowGroup {
///     ContentView()
/// }
/// .modelContainer(PersistenceController.shared.container)
///
/// // 在 Widget 中
/// import ReviewKit
/// let container = PersistenceController.shared.container
/// ```
///
/// ## 关键点
///
/// 1. 数据库存储在 App Groups 共享目录
/// 2. 图片也需要存储在共享目录（见 ImageStorageService）
/// 3. Widget 和 App 使用同一个数据库
/// 4. Model 类名统一为 `ReviewKit.ReviewItemModel`
public struct PersistenceController: Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = PersistenceController()
    
    // MARK: - Properties
    
    /// 共享的 ModelContainer
    public let container: ModelContainer
    
    /// 共享目录 URL（用于图片存储）
    public static var sharedContainerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }
    
    /// 数据库文件 URL
    public static var databaseURL: URL? {
        sharedContainerURL?.appendingPathComponent("NotBad.sqlite")
    }
    
    /// 图片存储目录 URL
    public static var imagesDirectoryURL: URL? {
        sharedContainerURL?.appendingPathComponent("Images")
    }
    
    // MARK: - Initialization
    
    /// 创建持久化控制器
    /// - Parameter inMemory: 是否使用内存存储（用于测试和预览）
    public init(inMemory: Bool = false) {
        let schema = Schema([ReviewItemModel.self])
        
        let modelConfiguration: ModelConfiguration
        
        if inMemory {
            // 内存存储（测试用）
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: true
            )
        } else if let appGroupURL = Self.sharedContainerURL {
            // ✅ 关键：使用 App Groups 共享目录
            let storeURL = appGroupURL.appendingPathComponent("NotBad.sqlite")
            modelConfiguration = ModelConfiguration(
                schema: schema,
                url: storeURL
            )
            logger.info("数据库路径: \(storeURL.path)")
        } else {
            // Fallback：默认路径（Widget 无法访问）
            logger.warning("App Groups 未配置，Widget 将无法访问数据")
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果失败，尝试删除旧数据库重建
            logger.error("ModelContainer 初始化失败: \(error.localizedDescription)")
            
            if let url = Self.databaseURL {
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            }
            
            // 重试
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("❌ 无法创建 ModelContainer: \(error)")
            }
        }
    }
    
    // MARK: - Preview Support
    
    /// 预览用的 ModelContainer
    @MainActor
    public static var preview: ModelContainer {
        PersistenceController(inMemory: true).container
    }
}
