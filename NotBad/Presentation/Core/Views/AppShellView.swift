//
//  AppShellView.swift
//  NotBad
//
//  Created by Refactor Bot on 9/22/25.
//

import SwiftUI

/// 轻量壳视图：承载环境注入与全局错误弹窗
///
/// SwiftUI 原生风格说明：
/// - 通过 `@EnvironmentObject` 读取根环境（由 `NotBadApp` 注入）；
/// - 使用 `withAppEnvironment(...)` 将其它依赖（EnvironmentValues 与其它 EnvironmentObject）
///   一次性注入到后续视图树，解耦具体视图与全局容器；
/// - 在壳层集中处理全局错误弹窗，避免在业务视图中散落重复的 `.alert(...)` 代码。
struct AppShellView: View {
    @EnvironmentObject var appEnvironment: AppEnvironment

    var body: some View {
        RootView()
            .withAppEnvironment(appEnvironment)
            .alert(item: Binding(
                get: { appEnvironment.errorHandler.currentError },
                set: { appEnvironment.errorHandler.currentError = $0 }
            )) { err in
                Alert(
                    title: Text("应用错误"),
                    message: Text(err.message),
                    dismissButton: .default(Text("确定"), action: {
                        appEnvironment.errorHandler.clearError()
                    })
                )
            }
            .onReceive(appEnvironment.errorHandler.$currentError) { newValue in
                if let e = newValue {
                    AppLogger.error(.app, "Global error [\(e.severity)] at \(e.timestamp): \(e.message)")
                } else {
                    AppLogger.debug(.app, "Global error cleared")
                }
            }
            .onAppear {
                AppLogger.info(.app, "AppShellView appeared; environment wired")
            }
    }
}

#Preview {
    // 预览中手动注入共享环境，确保预览可运行
    AppShellView()
        .environmentObject(AppEnvironment.shared)
}
