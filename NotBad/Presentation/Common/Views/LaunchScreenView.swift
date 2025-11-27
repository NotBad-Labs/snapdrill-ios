//
//  LaunchScreenView.swift
//  NotBad
//
//  启动页面视图
//

import SwiftUI

// MARK: - LaunchScreenView

/// 应用启动页面
///
/// 采用苹果推荐的 SwiftUI 启动页面设计，
/// 展示应用 Logo 和品牌标识，提供流畅的启动体验。
struct LaunchScreenView: View {
    
    // MARK: - State
    
    @State private var isAnimating = false
    @State private var showTagline = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.brand.primary.opacity(0.1),
                    Color(uiColor: .systemBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl) {
                Spacer()
                
                // Logo
                logoView
                
                // 应用名称
                Text("app_name")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                // 标语
                if showTagline {
                    Text("app_tagline")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                
                Spacer()
                Spacer()
                
                // 加载指示器
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(Color.brand.primary)
                    .scaleEffect(1.2)
                
                Spacer()
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // MARK: - Subviews
    
    /// Logo 视图
    private var logoView: some View {
        ZStack {
            // 背景圆
            Circle()
                .fill(Color.brand.primary.opacity(0.15))
                .frame(width: 120, height: 120)
                .scaleEffect(isAnimating ? 1.1 : 1.0)
            
            // Logo 图标
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundStyle(Color.brand.primary)
                .rotationEffect(.degrees(isAnimating ? 0 : -5))
        }
        .shadow(
            color: Color.brand.primary.opacity(0.3),
            radius: isAnimating ? 20 : 10,
            y: isAnimating ? 8 : 4
        )
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Logo 呼吸动画
        withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
        
        // 标语延迟显示
        withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
            showTagline = true
        }
    }
}

// MARK: - Preview

#Preview {
    LaunchScreenView()
}
