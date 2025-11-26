//
//  CardStyles.swift
//  NotBad
//
//  统一卡片样式定义
//

import SwiftUI

// MARK: - CardModifier

/// 卡片样式修饰器
///
/// 为视图添加统一的卡片外观。
///
/// ## 使用示例
///
/// ```swift
/// VStack {
///     Text("卡片内容")
/// }
/// .cardStyle()
/// ```
struct CardModifier: ViewModifier {
    
    /// 卡片样式变体
    var variant: CardVariant = .elevated
    
    /// 内边距
    var padding: CGFloat = DesignTokens.Spacing.lg
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(variant.background)
            .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg)
                    .strokeBorder(variant.borderColor, lineWidth: variant.borderWidth)
            )
            .shadow(variant.shadow)
    }
}

// MARK: - CardVariant

/// 卡片样式变体
enum CardVariant {
    /// 浮起卡片 - 有阴影
    case elevated
    
    /// 扁平卡片 - 无阴影
    case flat
    
    /// 边框卡片 - 有边框
    case outlined
    
    /// 填充卡片 - 强调背景
    case filled
    
    var background: Color {
        switch self {
        case .elevated, .flat, .outlined:
            return Color.semantic.secondaryBackground
        case .filled:
            return Color.brand.primary.opacity(0.08)
        }
    }
    
    var shadow: ShadowStyle {
        switch self {
        case .elevated:
            return DesignTokens.Shadow.light
        case .flat, .outlined, .filled:
            return ShadowStyle(color: .clear, radius: 0, x: 0, y: 0)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .outlined:
            return Color.semantic.separator
        case .filled:
            return Color.brand.primary.opacity(0.2)
        default:
            return .clear
        }
    }
    
    var borderWidth: CGFloat {
        switch self {
        case .outlined, .filled:
            return 1
        default:
            return 0
        }
    }
}

// MARK: - View Extension

extension View {
    
    /// 应用卡片样式
    ///
    /// - Parameters:
    ///   - variant: 卡片变体，默认浮起
    ///   - padding: 内边距
    /// - Returns: 应用卡片样式后的视图
    func cardStyle(
        _ variant: CardVariant = .elevated,
        padding: CGFloat = DesignTokens.Spacing.lg
    ) -> some View {
        modifier(CardModifier(variant: variant, padding: padding))
    }
}

// MARK: - ActionCard

/// 操作卡片组件
///
/// 带有点击操作的卡片。
struct ActionCard<Content: View>: View {
    
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var variant: CardVariant = .elevated
    
    var body: some View {
        Button(action: action) {
            content()
                .cardStyle(variant)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - ScaleButtonStyle

/// 缩放按钮样式
///
/// 点击时轻微缩放的按钮效果。
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview("Card Variants") {
    ScrollView {
        VStack(spacing: 16) {
            Text("Elevated").font(.caption).foregroundStyle(.secondary)
            Text("浮起卡片，有阴影")
                .frame(maxWidth: .infinity)
                .cardStyle(.elevated)
            
            Text("Flat").font(.caption).foregroundStyle(.secondary)
            Text("扁平卡片，无阴影")
                .frame(maxWidth: .infinity)
                .cardStyle(.flat)
            
            Text("Outlined").font(.caption).foregroundStyle(.secondary)
            Text("边框卡片，有边框")
                .frame(maxWidth: .infinity)
                .cardStyle(.outlined)
            
            Text("Filled").font(.caption).foregroundStyle(.secondary)
            Text("填充卡片，强调背景")
                .frame(maxWidth: .infinity)
                .cardStyle(.filled)
        }
        .padding()
    }
}


