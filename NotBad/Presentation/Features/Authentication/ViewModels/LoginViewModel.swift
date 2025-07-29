import SwiftUI
import Combine

/// 登录视图模型 - 处理登录业务逻辑
/// 位置: Presentation/Features/Authentication/ViewModels/LoginViewModel.swift
@MainActor
final class LoginViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var selectedLoginMethod: LoginMethod = .email
    @Published var email: String = ""
    @Published var phone: String = ""
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberPassword: Bool = false
    @Published var isPasswordVisible: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Computed Properties
    
    /// 当前输入方式对应的值
    var currentInputValue: String {
        switch selectedLoginMethod {
        case .email: return email
        case .phone: return phone
        case .username: return username
        }
    }
    
    /// 检查输入是否有效
    var isInputValid: Bool {
        let inputValue = currentInputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        let passwordValue = password.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return !inputValue.isEmpty && !passwordValue.isEmpty
    }
    
    // MARK: - Methods
    
    /// 更新当前输入方式的值
    /// - Parameter value: 新的输入值
    func updateInputValue(_ value: String) {
        switch selectedLoginMethod {
        case .email: 
            email = value
        case .phone: 
            phone = value
        case .username: 
            username = value
        }
    }
    
    /// 执行登录操作
    func login() async {
        guard isInputValid else {
            errorMessage = "请填写完整的登录信息"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // 模拟网络请求延迟
            try await Task.sleep(for: .seconds(2))
            
            // 这里应该调用实际的登录用例
            // let result = try await loginUseCase.execute(request: createLoginRequest())
            
            // 模拟登录成功
            print("登录成功 - 方式: \(selectedLoginMethod.title)")
            print("用户名: \(currentInputValue)")
            
            // 登录成功后的处理
            await handleLoginSuccess()
            
        } catch {
            errorMessage = "登录失败，请检查用户名和密码"
            print("登录失败: \(error)")
        }
        
        isLoading = false
    }
    
    /// Apple 登录
    func loginWithApple() async {
        isLoading = true
        
        do {
            // 模拟 Apple 登录
            try await Task.sleep(for: .seconds(1))
            print("Apple 登录成功")
            await handleLoginSuccess()
        } catch {
            errorMessage = "Apple 登录失败"
        }
        
        isLoading = false
    }
    
    /// 微信登录
    func loginWithWeChat() async {
        isLoading = true
        
        do {
            // 模拟微信登录
            try await Task.sleep(for: .seconds(1))
            print("微信登录成功")
            await handleLoginSuccess()
        } catch {
            errorMessage = "微信登录失败"
        }
        
        isLoading = false
    }
    
    /// 忘记密码
    func forgotPassword() {
        print("跳转到忘记密码页面")
        // 这里应该触发导航到忘记密码页面
    }
    
    /// 注册新账户
    func signUp() {
        print("跳转到注册页面")
        // 这里应该触发导航到注册页面
    }
    
    /// 清除错误信息
    func clearError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    /// 处理登录成功
    private func handleLoginSuccess() async {
        // 清除敏感信息
        if !rememberPassword {
            password = ""
        }
        
        // 这里应该触发导航到主页面
        print("导航到主页面")
    }
    
    /// 创建登录请求
    private func createLoginRequest() -> LoginRequest {
        switch selectedLoginMethod {
        case .email:
            return .email(email: email, password: password)
        case .phone:
            return .phone(phone: phone, password: password)
        case .username:
            return .username(username: username, password: password)
        }
    }
}

// MARK: - 登录请求数据结构
enum LoginRequest {
    case email(email: String, password: String)
    case phone(phone: String, password: String)
    case username(username: String, password: String)
}