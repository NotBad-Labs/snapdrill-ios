//
//  AppShellView.swift
//  NotBad
//
//  Created by Refactor Bot on 9/22/25.
//

import SwiftUI

/// 轻量壳视图：承载环境注入与全局错误弹窗
struct AppShellView: View {
    @ObservedObject var appEnvironment: AppEnvironment

    var body: some View {
        RootView()
            .withAppEnvironment(appEnvironment)
            .alert(item: $appEnvironment.errorHandler.currentError) { err in
                Alert(
                    title: Text("应用错误"),
                    message: Text(err.message),
                    dismissButton: .default(Text("确定"), action: {
                        appEnvironment.errorHandler.clearError()
                    })
                )
            }
    }
}

#Preview {
    AppShellView(appEnvironment: AppEnvironment.shared)
}
