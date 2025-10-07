//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/20/25.
//

import SwiftUI

/// NotBad 错题本应用主入口
///
/// 职责：
/// - 应用配置和启动
/// - 场景管理
/// - 根视图展示
@main
struct NotBadApp: App {
    
    // MARK: - Scene
    
    var body: some Scene {
        WindowGroup {
            CoordinatorView()
                .modelContainer(DataManager.shared.container)
        }
    }
}
