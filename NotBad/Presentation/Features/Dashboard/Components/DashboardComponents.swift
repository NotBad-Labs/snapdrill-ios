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
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                    Text("dashboard_welcome_hello")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("dashboard_welcome_subtitle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                // 更精致的动画图标
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.brand.warning.opacity(0.3), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 40
                            )
                        )
                        .frame(width: 80, height: 80)
                        .scaleEffect(isAnimating ? 1.1 : 0.9)

                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.brand.warning, Color.brand.error],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(isAnimating ? 5 : -5))
                }
                .accessibilityHidden(true)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .background(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.brand.primary.opacity(0.08),
                            Color.brand.secondary.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.xl)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.brand.primary.opacity(0.2),
                            Color.brand.secondary.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("dashboard_welcome_accessibility")
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - StatCard

/// 统计卡片组件
struct StatCard: View {
    let title: LocalizedStringKey
    let value: String
    let icon: String
    let color: Color

    @State private var isAppeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            HStack {
                // 图标带背景
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 40, height: 40)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(color)
                }
                .accessibilityHidden(true)

                Spacer()
            }

            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .contentTransition(.numericText())

                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .shadow(DesignTokens.Shadow.light)
        .scaleEffect(isAppeared ? 1 : 0.95)
        .opacity(isAppeared ? 1 : 0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(value)
        .onAppear {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isAppeared = true
            }
        }
    }
}

// MARK: - QuickActionButton

/// 快捷操作按钮组件
struct QuickActionButton: View {
    let title: LocalizedStringKey
    let icon: String
    let color: Color

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            // 图标带背景
            ZStack {
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.sm)
                    .fill(color.opacity(0.12))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(color)
            }
            .accessibilityHidden(true)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(DesignTokens.Spacing.md)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        .shadow(DesignTokens.Shadow.light)
        .scaleEffect(isPressed ? 0.98 : 1)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
    }
}
