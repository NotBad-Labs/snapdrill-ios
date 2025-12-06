//
//  PersistenceController.swift
//  NotBad
//
//  ⚠️ 已迁移到 ReviewKit Package
//
//  这个文件已迁移到 Packages/ReviewKit/Sources/ReviewKit/Data/
//  待 Xcode 添加 ReviewKit 依赖后删除此文件。
//
//  迁移步骤：
//  1. 在 Xcode 中，选择 NotBad project
//  2. 点击 "Package Dependencies"
//  3. 添加本地 Package: Packages/ReviewKit
//  4. 在 NotBad target 的 "Frameworks, Libraries..." 中添加 ReviewKit
//  5. 删除此文件
//  6. 在需要的地方添加 `import ReviewKit`
//

import SwiftData
import Foundation

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
/// WindowGroup {
///     ContentView()
/// }
/// .modelContainer(PersistenceController.shared.container)
///
/// // 在 Widget 中
/// import NotBad // 或直接使用此文件
/// let container = PersistenceController.shared.container
/// ```
///
/// ## 关键点
///
/// 1. 数据库存储在 App Groups 共享目录
/// 2. 图片也需要存储在共享目录（见 ImageStorageService）
/// 3. Widget 和 App 使用同一个数据库
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
            print("📁 数据库路径: \(storeURL.path)")
        } else {
            // Fallback：默认路径（Widget 无法访问）
            print("⚠️ App Groups 未配置，Widget 将无法访问数据")
            modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }
        
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // 如果失败，尝试删除旧数据库重建
            print("❌ ModelContainer 初始化失败: \(error)")
            
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
