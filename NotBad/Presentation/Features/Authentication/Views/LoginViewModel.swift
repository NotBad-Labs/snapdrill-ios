//
//  LoginViewModel.swift
//  NotBad
//
//  Created by Gemini on 2025/07/21.
//

import Foundation
import Observation // 导入 Observation 框架以使用 @Observable

/// 登录视图的模型，负责管理登录相关的状态和逻辑。
/// 使用 @Observable 宏，当其属性变化时，SwiftUI 视图会自动更新。
/// 使用 @MainActor 确保所有 UI 相关的状态更新都在主线程上进行。
@MainActor
@Observable
final class LoginViewModel {
    // 用户名输入框的文本
    var username = ""
    // 密码输入框的文本
    var password = ""
    // 是否显示加载指示器
    var isLoading = false
    // 错误消息，如果发生错误则显示
    var errorMessage: String? = nil
    // 登录是否成功
    var loginSuccess = false

    /// 检查登录按钮是否应该启用。
    /// 只有当用户名和密码都不为空时，按钮才可用。
    var isLoginButtonEnabled: Bool {
        !username.isEmpty && !password.isEmpty && !isLoading
    }

    /// 执行登录操作。
    /// 这是一个模拟的异步操作，实际应用中会调用应用服务层。
    func performLogin() async {
        isLoading = true // 开始加载
        errorMessage = nil // 清除之前的错误消息

        // 模拟网络请求延迟
        try? await Task.sleep(for: .seconds(2))

        // 模拟登录逻辑
        if username == "test" && password == "password" {
            loginSuccess = true
            print("登录成功！")
        } else {
            errorMessage = "用户名或密码错误。"
            print("登录失败：\(errorMessage ?? "")")
        }

        isLoading = false // 结束加载
    }
}
