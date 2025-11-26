//
//  DashboardComponents.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - WelcomeCard

/// 欢迎卡片组件
struct WelcomeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("Hello！")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("继续你的学习之旅")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.brand.warning, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .symbolEffect(.bounce)
                    .accessibilityHidden(true)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(
            LinearGradient(
                colors: [Color.brand.primary.opacity(0.1), Color.brand.secondary.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Hello，继续你的学习之旅")
    }
}

// MARK: - StatCard

/// 统计卡片组件
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .accessibilityHidden(true)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title)：\(value)")
    }
}

// MARK: - QuickActionButton

/// 快捷操作按钮组件
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
