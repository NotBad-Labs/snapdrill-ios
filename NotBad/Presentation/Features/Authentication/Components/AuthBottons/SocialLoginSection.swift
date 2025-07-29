import SwiftUI

/// 社交登录区域组件 - 修复版本
/// 位置: Presentation/Features/Authentication/Components/SocialLoginSection.swift
struct SocialLoginSection: View {
    let onAppleLogin: () -> Void
    let onWeChatLogin: () -> Void
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            // 说明文字
            Text("快速登录")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 社交登录图标行
            HStack(spacing: 24) {
                // Apple 登录
                SocialLoginIconButton(
                    provider: .apple,
                    isLoading: isLoading,
                    action: onAppleLogin
                )
                
                // 微信登录
                SocialLoginIconButton(
                    provider: .wechat,
                    isLoading: isLoading,
                    action: onWeChatLogin
                )
            }
        }
    }
}

/// 社交登录图标按钮
struct SocialLoginIconButton: View {
    let provider: SocialProvider
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景圆圈
                Circle()
                    .fill(provider.backgroundColor)  // 现在使用 Color 类型
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(provider.borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: provider.shadowColor,
                        radius: isPressed ? 2 : 6,
                        x: 0,
                        y: isPressed ? 1 : 3
                    )
                
                // 图标
                provider.icon
                    .frame(width: 24, height: 24)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .scaleEffect(isLoading ? 0.9 : 1.0)
            .opacity(isLoading ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        })
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
        // 添加触觉反馈
        .onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            action()
        }
    }
}

// MARK: - 社交登录提供商定义 - 修复版本
enum SocialProvider: CaseIterable {
    case apple
    case wechat
    
    var name: String {
        switch self {
        case .apple: return "Apple"
        case .wechat: return "微信"
        }
    }
    
    var icon: some View {
        switch self {
        case .apple:
            return AnyView(
                Image(systemName: "applelogo")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white)
            )
        case .wechat:
            return AnyView(
                ZStack {
                    // 微信绿色背景
                    Circle()
                        .fill(Color(red: 0.09, green: 0.7, blue: 0.27))
                        .frame(width: 28, height: 28)
                    
                    // 微信图标 - 简化版本
                    VStack(spacing: 1) {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 6, height: 6)
                            Circle()
                                .fill(Color.white)
                                .frame(width: 4, height: 4)
                        }
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white)
                            .frame(width: 12, height: 3)
                    }
                }
            )
        }
    }
    
    // 修复：返回 Color 类型而不是 some View
    var backgroundColor: Color {
        switch self {
        case .apple: return Color.black
        case .wechat: return Color(.systemBackground)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .apple: return Color.clear
        case .wechat: return Color(.separator)
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .apple: return Color.black.opacity(0.2)
        case .wechat: return Color.black.opacity(0.1)
        }
    }
}

// MARK: - 更简洁的版本 (水平排列，更紧凑)
struct CompactSocialLoginSection: View {
    let onAppleLogin: () -> Void
    let onWeChatLogin: () -> Void
    let isLoading: Bool
    
    var body: some View {
        HStack(spacing: 20) {
            // 左侧分割线
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
            
            // Apple 登录
            CompactSocialButton(
                provider: .apple,
                isLoading: isLoading,
                action: onAppleLogin
            )
            
            // 微信登录
            CompactSocialButton(
                provider: .wechat,
                isLoading: isLoading,
                action: onWeChatLogin
            )
            
            // 右侧分割线
            Rectangle()
                .fill(Color(.separator))
                .frame(height: 1)
        }
    }
}

/// 更紧凑的社交按钮 (44x44)
struct CompactSocialButton: View {
    let provider: SocialProvider
    let isLoading: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                // 背景 - 修复版本
                RoundedRectangle(cornerRadius: 12)
                    .fill(provider.backgroundColor)  // 现在使用 Color 类型
                    .frame(width: 44, height: 44)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(provider.borderColor, lineWidth: 1)
                    )
                    .shadow(
                        color: provider.shadowColor,
                        radius: isPressed ? 1 : 4,
                        x: 0,
                        y: isPressed ? 1 : 2
                    )
                
                // 图标 - 稍小一些
                provider.icon
                    .scaleEffect(0.8)
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isLoading ? 0.6 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isLoading)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, perform: {}, onPressingChanged: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        })
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isLoading)
    }
}

// MARK: - 预览
#Preview {
    VStack(spacing: 40) {
        // 标准版本
        VStack {
            Text("标准版本")
                .font(.headline)
            
            SocialLoginSection(
                onAppleLogin: { print("Apple 登录") },
                onWeChatLogin: { print("微信登录") },
                isLoading: false
            )
        }
        
        Divider()
        
        // 紧凑版本
        VStack {
            Text("紧凑版本")
                .font(.headline)
            
            CompactSocialLoginSection(
                onAppleLogin: { print("Apple 登录") },
                onWeChatLogin: { print("微信登录") },
                isLoading: false
            )
        }
        
        Divider()
        
        // 加载状态
        VStack {
            Text("加载状态")
                .font(.headline)
            
            SocialLoginSection(
                onAppleLogin: { print("Apple 登录") },
                onWeChatLogin: { print("微信登录") },
                isLoading: true
            )
        }
    }
    .padding(40)
    .background(Color(.systemGroupedBackground))
}