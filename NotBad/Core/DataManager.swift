//
//  DataManager.swift
//  NotBad
//
//  Created by Yiming Liao on 10/7/25.
//

import SwiftUI
import SwiftData

/// 数据管理器
///
/// 职责：
/// - 管理 SwiftData 模型容器
/// - 处理数据库配置和迁移
/// - 提供数据访问接口
@MainActor
final class DataManager {
    
    // MARK: - Singleton
    
    static let shared = DataManager()
    
    // MARK: - Properties
    
    let container: ModelContainer
    
    // MARK: - Initialization
    
    private init() {
        let schema = Schema([
            // 这里将来添加数据模型
            // ReviewItem.self,
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true
        )
        
        do {
            container = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("无法创建 ModelContainer: \(error)")
        }
    }
}
