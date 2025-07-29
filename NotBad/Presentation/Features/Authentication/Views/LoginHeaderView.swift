import SwiftUI

/// 登录页面头部视图
/// 位置: Presentation/Features/Authentication/Views/LoginHeaderView.swift
struct LoginHeaderView: View {
    var body: some View {
        VStack(spacing: 16) {
            // App Logo
            appLogo
            
            // App 名称和描述
            appInfo
        }
        .padding(.bottom, 40)
    }
    
    // MARK: - Logo 组件
    private var appLogo: some View {
        ZStack {
            // 渐变背景
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [.blue, .purple]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            
            // Logo 文字
            Text("NB")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
    }
    
    // MARK: - App 信息
    private var appInfo: some View {
        VStack(spacing: 8) {
            // App 名称
            Text("NotBad")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            // App 描述
            Text("智能错题记录，让学习更高效")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - 预览
#Preview {
    VStack {
        LoginHeaderView()
        
        Spacer()
    }
    .background(
        LinearGradient(
            gradient: Gradient(colors: [
                Color.blue.opacity(0.1),
                Color.white,
                Color.purple.opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}