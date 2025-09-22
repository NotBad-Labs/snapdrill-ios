//
//  NotBadApp.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import SwiftUI

/// SwiftUI 原生入口写法（docs as code）
/// - 仅在此处构建根环境对象，并通过 `.environmentObject(...)` 注入整个视图树；
/// - 环境对象的生命周期与 `App` 同步（`@StateObject`），避免重复初始化；
/// - 使用 `@MainActor` 明确入口与 UI 绑定，降低并发隔离噪音；
/// - 业务视图避免显式从构造器传入全局环境，优先通过 EnvironmentObject/EnvironmentValues 读取。
@MainActor
@main
struct NotBadApp: App {
    
    // MARK: - Environment
    
    /// 应用环境管理器（统一管理所有依赖）
    ///
    /// 说明：
    /// - 使用 `@StateObject` 确保 `AppEnvironment` 在应用生命周期内只创建一次；
    /// - 通过 `WindowGroup` 的 `.environmentObject(appEnvironment)` 将其分发给子视图；
    /// - 其余环境（如 `serviceContainer`、`mainCoordinator` 等）会在下游通过
    ///   `withAppEnvironment(...)` 进一步注入到 EnvironmentValues 与 EnvironmentObject。
    @StateObject private var appEnvironment = AppEnvironment.make()
    
    // MARK: - App Scene
    
    var body: some Scene {
        WindowGroup {
            // 仅注入根环境对象，其余环境由下游壳视图进行组合注入
            AppShellView()
                .environmentObject(appEnvironment)
                .onAppear {
                    AppLogger.info(.app, "App launched")
                }
        }
    }
}
