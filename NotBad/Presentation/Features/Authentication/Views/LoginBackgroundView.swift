import SwiftUI

/// 登录页面背景视图
/// 位置: Presentation/Features/Authentication/Views/LoginBackgroundView.swift
struct LoginBackgroundView: View {
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBlue).opacity(0.1),
                Color(.systemBackground),
                Color(.systemPurple).opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 预览
#Preview {
    LoginBackgroundView()
}