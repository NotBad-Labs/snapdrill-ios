import SwiftData
import Foundation
import os.log
import ReviewKitModels

private let logger = Logger(subsystem: "com.notbad.reviewkit", category: "Persistence")

/// 持久化控制器（App/Widget 共享）
///
/// ## 单例模式优化
/// - 使用静态方法封装对 shared 实例的访问
/// - 避免直接暴露大量 @MainActor 静态属性
/// - 提供便捷的访问方法
@MainActor
public final class PersistenceController: Sendable {
    
    // MARK: - Singleton
    
    /// 共享实例
    public static let shared = PersistenceController()
    
    // MARK: - Properties
    
    public let container: ModelContainer
    private let config: ReviewKitConfiguration
    
    // MARK: - Initialization
    
    public init(configuration: ReviewKitConfiguration = .shared, inMemory: Bool = false) {
        self.config = configuration
        let schema = Schema([ReviewItemModel.self])
        let modelConfiguration: ModelConfiguration
        if inMemory {
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        } else if let appGroupURL = configuration.sharedContainerURL {
            let storeURL = appGroupURL.appendingPathComponent(configuration.databaseFileName)
            modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
            logger.info("数据库路径: \(storeURL.path)")
        } else {
            logger.warning("App Groups '\(configuration.appGroupIdentifier)' 未配置，Widget 将无法访问数据")
            modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        }
        do {
            container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            logger.error("ModelContainer 初始化失败: \(error.localizedDescription)")
            if let url = configuration.databaseURL {
                try? FileManager.default.removeItem(at: url)
                try? FileManager.default.removeItem(at: url.appendingPathExtension("shm"))
                try? FileManager.default.removeItem(at: url.appendingPathExtension("wal"))
            }
            do {
                container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("❌ 无法创建 ModelContainer: \(error)")
            }
        }
    }
    
    // MARK: - Static Accessors
    
    /// 共享容器 URL（App Group）
    public static var sharedContainerURL: URL? {
        ReviewKitConfiguration.shared.sharedContainerURL
    }
    
    /// 数据库文件 URL
    public static var databaseURL: URL? {
        ReviewKitConfiguration.shared.databaseURL
    }
    
    /// 图片目录 URL
    public static var imagesDirectoryURL: URL? {
        ReviewKitConfiguration.shared.imagesDirectoryURL
    }
    
    /// 预览容器（用于 SwiftUI Preview）
    public static var preview: ModelContainer {
        PersistenceController(inMemory: true).container
    }
}