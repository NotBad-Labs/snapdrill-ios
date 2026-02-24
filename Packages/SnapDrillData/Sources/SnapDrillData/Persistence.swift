//
//  Persistence.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Updated by SnapDrill Architect on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  SwiftData 持久化控制器，管理 ModelContainer
//
//  IMPORTANT: iOS 26 SwiftData 已知问题 workaround
//  - 避免使用 Migration Plan（iOS 26.1 数组类型变化导致迁移失败）
//  - 使用最简单的初始化方式
//  - 确保所有模型属性都有默认值或可选
//

import SwiftData
import OSLog
import UIKit

private let logger = Logger(subsystem: "com.snapdrill.app", category: "Persistence")

@MainActor
public class PersistenceController {
    public static let shared = PersistenceController()
    
    public let container: ModelContainer
    
    /// 标记是否使用内存存储（降级模式）
    public private(set) var isUsingInMemoryFallback: Bool = false
    
    /// 持久化错误（如果有）
    public private(set) var initializationError: PersistenceError?
    
    public init(inMemory: Bool = false) {
        logger.info("🔧 Initializing SwiftData (iOS 26 workaround)")
        logger.info("Device: \(UIDevice.current.model), iOS: \(UIDevice.current.systemVersion)")
        
        do {
            // iOS 26 Workaround: 使用最简单的初始化方式
            // 不使用 ModelConfiguration schema 参数（iOS 26.1 bug）
            // 不使用 Migration Plan（数组类型变化问题）
            
            if inMemory {
                logger.info("Creating in-memory container...")
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                self.container = try ModelContainer(
                    for: ReviewItemModel.self,
                         SubjectModel.self,
                         SourceModel.self,
                         TagModel.self,
                    configurations: config
                )
                self.isUsingInMemoryFallback = true
            } else {
                logger.info("Creating persistent container...")
                // 最简单的方式 - 让 SwiftData 自动处理一切
                self.container = try ModelContainer(
                    for: ReviewItemModel.self,
                         SubjectModel.self,
                         SourceModel.self,
                         TagModel.self
                )
                self.isUsingInMemoryFallback = false
            }
            
            self.initializationError = nil
            logger.info("✅ Container initialized successfully")
            
        } catch {
            logger.error("❌ Primary initialization failed: \(error.localizedDescription)")
            logger.error("Error details: \(String(describing: error))")
            
            // iOS 26 Fallback: 强制使用内存存储
            do {
                logger.warning("⚠️ Attempting in-memory fallback...")
                let config = ModelConfiguration(isStoredInMemoryOnly: true)
                self.container = try ModelContainer(
                    for: ReviewItemModel.self,
                         SubjectModel.self,
                         SourceModel.self,
                         TagModel.self,
                    configurations: config
                )
                
                self.isUsingInMemoryFallback = true
                self.initializationError = PersistenceError.containerInitializationFailed(underlying: error)
                
                logger.warning("⚠️ Using in-memory storage (data will not persist)")
                logger.warning("⚠️ This is a workaround for iOS 26 SwiftData issues")
                logger.warning("⚠️ Recommendation: Delete app and reinstall to clear corrupted data")
                
            } catch let fallbackError {
                logger.critical("💀 In-memory fallback failed: \(fallbackError.localizedDescription)")
                logger.critical("Error details: \(String(describing: fallbackError))")
                
                fatalError("""
                    SwiftData 初始化失败
                    
                    这是 iOS 26 的已知问题。请尝试：
                    
                    1. 完全删除应用
                    2. 重启设备
                    3. 重新安装应用
                    
                    如果问题持续：
                    - 检查设备存储空间
                    - 更新到最新 iOS 版本
                    - 提交 bug 报告到 Apple
                    
                    技术详情：
                    Primary error: \(error.localizedDescription)
                    Fallback error: \(fallbackError.localizedDescription)
                    
                    已知问题：iOS 26.1 SwiftData 数组类型迁移失败
                    参考：https://developer.apple.com/forums
                    """)
            }
        }
    }
}
