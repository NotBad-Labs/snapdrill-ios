//
//  LoginFormCard.swift
//  NotBad
//
//  Created by YIMING LIAO on 2025/7/21.
//


import SwiftUI

/// 登录表单卡片视图 - 协调动画版本
/// 位置: Presentation/Features/Authentication/Views/LoginFormCard.swift
struct LoginFormCard: View {
    @ObservedObject var viewModel: LoginViewModel
    
    // 跟踪前一个选择的方法，用于确定动画方向
    @State private var previousMethod: LoginMethod = .email
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 24) {
                // 标题
                cardTitle
                
                // 错误提示
                errorMessage
                
                // 登录方式选择
                LoginMethodSelector(selectedMethod: $viewModel.selectedLoginMethod)
                
                // 输入字段组 - 整体动画
                inputFieldsGroup
                
                // 记住密码和忘记密码
                rememberAndForgotSection
                
                // 登录按钮
                PrimaryAuthButton(
                    title: "登录",
                    isLoading: viewModel.isLoading
                ) {
                    Task {
                        await viewModel.login()
                    }
                }
                
                // 社交登录区域
                socialLoginSection
                
                // 注册提示
                signUpPrompt
            }
            .padding(32)
        }
        .background(cardBackground)
        .onChange(of: viewModel.selectedLoginMethod) { oldValue, newValue in
            previousMethod = oldValue
        }
    }
    
    // MARK: - 卡片标题
    private var cardTitle: some View {
        Text("登录账户")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    // MARK: - 错误提示
    @ViewBuilder
    private var errorMessage: some View {
        if let errorMessage = viewModel.errorMessage {
            HStack {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button("✕") {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.clearError()
                    }
                }
                .foregroundColor(.red)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.red.opacity(0.1))
                    .stroke(Color.red.opacity(0.3), lineWidth: 1)
            )
            .transition(.asymmetric(
                insertion: .scale(scale: 0.8).combined(with: .opacity),
                removal: .scale(scale: 0.8).combined(with: .opacity)
            ))
        }
    }
    
    // MARK: - 输入字段组 - 关键修改点
    private var inputFieldsGroup: some View {
        VStack(spacing: 16) {
            // 动态输入字段
            dynamicInputField
            
            // 密码输入字段
            PasswordField(
                password: $viewModel.password,
                isVisible: $viewModel.isPasswordVisible,
                placeholder: "请输入密码"
            )
        }
        .transition(getTransition())
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewModel.selectedLoginMethod)
        .id("input-fields-\(viewModel.selectedLoginMethod.rawValue)") // 强制重建整个组
    }
    
    // MARK: - 动态输入字段
    private var dynamicInputField: some View {
        Group {
            switch viewModel.selectedLoginMethod {
            case .email:
                EmailField(
                    text: $viewModel.email,
                    placeholder: viewModel.selectedLoginMethod.placeholder
                )
                
            case .phone:
                PhoneField(
                    text: $viewModel.phone,
                    placeholder: viewModel.selectedLoginMethod.placeholder
                )
                
            case .username:
                UsernameField(
                    text: $viewModel.username,
                    placeholder: viewModel.selectedLoginMethod.placeholder
                )
            }
        }
    }
    
    // MARK: - 获取过渡动画
    private func getTransition() -> AnyTransition {
        let methodIndex: [LoginMethod: Int] = [
            .email: 0,
            .phone: 1,
            .username: 2
        ]
        
        let currentIndex = methodIndex[viewModel.selectedLoginMethod] ?? 0
        let previousIndex = methodIndex[previousMethod] ?? 0
        
        let isMovingRight = currentIndex > previousIndex
        
        return .asymmetric(
            insertion: .move(edge: isMovingRight ? .trailing : .leading)
                .combined(with: .opacity.animation(.easeIn(duration: 0.2))),
            removal: .move(edge: isMovingRight ? .leading : .trailing)
                .combined(with: .opacity.animation(.easeOut(duration: 0.2)))
        )
    }
    
    // MARK: - 记住密码和忘记密码
    private var rememberAndForgotSection: some View {
        HStack {
            // 记住密码
            HStack(spacing: 8) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.rememberPassword.toggle()
                    }
                }) {
                    Image(systemName: viewModel.rememberPassword ? "checkmark.square.fill" : "square")
                        .foregroundColor(viewModel.rememberPassword ? .blue : .secondary)
                        .font(.system(size: 16))
                }
                .buttonStyle(PlainButtonStyle())
                
                Text("记住密码")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 忘记密码
            Button(action: {
                viewModel.forgotPassword()
            }) {
                Text("忘记密码？")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
        }
    }
    
    // MARK: - 社交登录区域
    private var socialLoginSection: some View {
        CompactSocialLoginSection(
            onAppleLogin: {
                Task {
                    await viewModel.loginWithApple()
                }
            },
            onWeChatLogin: {
                Task {
                    await viewModel.loginWithWeChat()
                }
            },
            isLoading: viewModel.isLoading
        )
    }
    
    // MARK: - 注册提示
    private var signUpPrompt: some View {
        HStack {
            Text("还没有账户？")
                .font(.footnote)
                .foregroundColor(.secondary)
            
            Button(action: {
                viewModel.signUp()
            }) {
                Text("立即注册")
                    .font(.footnote)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(viewModel.isLoading ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: viewModel.isLoading)
        }
    }
    
    // MARK: - 卡片背景
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 24)
            .fill(Color(.systemBackground))
            .shadow(color: .black.opacity(0.08), radius: 20, x: 0, y: 10)
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - 预览
#Preview {
    ScrollView {
        LoginFormCard(viewModel: LoginViewModel())
            .padding()
    }
    .background(LoginBackgroundView())
}