//
//  ProfileUserCard.swift
//  NotBad
//
//  用户卡片组件
//
//  单一职责：展示用户头像、昵称，支持点击编辑
//

import SwiftUI

// MARK: - Profile User Card

/// 用户卡片组件
///
/// 显示用户的头像和昵称，支持点击进入编辑界面。
/// 头像使用渐变背景和 SF Symbol 图标。
struct ProfileUserCard: View {
    
    // MARK: - Properties
    
    let nickname: String
    let avatar: String
    let gradientColors: [Color]
    let onTap: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignTokens.Spacing.lg) {
                avatarView
                userInfo
                Spacer()
                chevron
            }
            .padding(.vertical, DesignTokens.Spacing.sm)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Subviews

private extension ProfileUserCard {
    
    /// 头像视图
    var avatarView: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: gradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 64, height: 64)
                .shadow(color: gradientColors[0].opacity(0.3), radius: 8, x: 0, y: 4)
            
            Image(systemName: avatar)
                .font(.system(size: 28, weight: .medium))
                .foregroundStyle(.white)
        }
    }
    
    /// 用户信息
    var userInfo: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(nickname)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
            
            Text("profile_subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    /// 右箭头
    var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.tertiary)
    }
}

// MARK: - Preview

#Preview {
    List {
        Section {
            ProfileUserCard(
                nickname: "小明",
                avatar: "graduationcap.fill",
                gradientColors: [.blue, .purple],
                onTap: {}
            )
        }
    }
}
