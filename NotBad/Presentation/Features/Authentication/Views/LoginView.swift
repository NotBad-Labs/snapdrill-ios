import SwiftUI

/// 主登录视图
/// 位置: Presentation/Features/Authentication/Views/LoginView.swift
struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 0) {
                    // Logo和标题区域
                    LoginHeaderView()
                        .padding(.top, max(geometry.safeAreaInsets.top + 20, 60))
                    
                    // 登录表单卡片
                    LoginFormCard(viewModel: viewModel)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(LoginBackgroundView())
        .ignoresSafeArea()
        .onTapGesture {
            // 点击空白区域收起键盘
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

// MARK: - 预览
#Preview {
    LoginView()
}