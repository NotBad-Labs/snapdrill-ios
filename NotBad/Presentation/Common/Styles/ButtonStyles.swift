//
//  ButtonStyles.swift
//  NotBad
//
//  统一按钮样式定义
//

import SwiftUI

// MARK: - PrimaryButtonStyle

/// 主要按钮样式
///
/// 用于最重要的操作，如「保存」「开始复习」。
///
/// ## 使用示例
///
/// ```swift
/// Button("保存") {
///     save()
/// }
/// .buttonStyle(.primary)
/// ```
struct PrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    /// 是否全宽
    var fullWidth: Bool = false

    /// 尺寸
    var size: ButtonSize = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled {
            return .gray.opacity(0.3)
        }
        if isPressed {
            return Color.brand.primary.opacity(0.8)
        }
        return Color.brand.primary
    }
}

// MARK: - SecondaryButtonStyle

/// 次要按钮样式
///
/// 用于次要操作，如「取消」「跳过」。
struct SecondaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    var size: ButtonSize = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .fontWeight(.medium)
            .foregroundStyle(isEnabled ? Color.brand.primary : .gray)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .overlay(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .strokeBorder(isEnabled ? Color.brand.primary : .gray, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        isPressed ? Color.brand.primary.opacity(0.1) : .clear
    }
}

// MARK: - GhostButtonStyle

/// 幽灵按钮样式
///
/// 用于低优先级操作或密集布局中的按钮。
struct GhostButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    var size: ButtonSize = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .fontWeight(.medium)
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(configuration.isPressed ? Color.gray.opacity(0.1) : .clear)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        if !isEnabled { return .gray }
        return isPressed ? Color.brand.primary.opacity(0.7) : Color.brand.primary
    }
}

// MARK: - DestructiveButtonStyle

/// 危险按钮样式
///
/// 用于删除、重置等破坏性操作。
struct DestructiveButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    var size: ButtonSize = .medium

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(
                RoundedRectangle(cornerRadius: size.cornerRadius)
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        if !isEnabled { return .gray.opacity(0.3) }
        return isPressed ? Color.brand.error.opacity(0.8) : Color.brand.error
    }
}

// MARK: - IconButtonStyle

/// 图标按钮样式
///
/// 用于工具栏或紧凑布局中的纯图标按钮。
struct IconButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled

    /// 按钮尺寸
    var size: CGFloat = 44

    /// 是否有背景
    var hasBackground: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: size * 0.45))
            .foregroundStyle(isEnabled ? Color.brand.primary : .gray)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor(isPressed: configuration.isPressed))
            )
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(DesignTokens.Animation.fast, value: configuration.isPressed)
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard hasBackground else { return .clear }
        return isPressed ? Color.brand.primary.opacity(0.15) : Color.brand.primary.opacity(0.1)
    }
}

// MARK: - ButtonSize

/// 按钮尺寸
enum ButtonSize {
    case small
    case medium
    case large

    var font: Font {
        switch self {
        case .small: .subheadline
        case .medium: .body
        case .large: .title3
        }
    }

    var horizontalPadding: CGFloat {
        switch self {
        case .small: 12
        case .medium: 20
        case .large: 28
        }
    }

    var verticalPadding: CGFloat {
        switch self {
        case .small: 8
        case .medium: 12
        case .large: 16
        }
    }

    var cornerRadius: CGFloat {
        switch self {
        case .small: DesignTokens.CornerRadius.sm
        case .medium: DesignTokens.CornerRadius.md
        case .large: DesignTokens.CornerRadius.lg
        }
    }
}

// MARK: - ButtonStyle Extensions

extension ButtonStyle where Self == PrimaryButtonStyle {
    /// 主要按钮样式
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }

    /// 主要按钮样式（全宽）
    static var primaryFullWidth: PrimaryButtonStyle { PrimaryButtonStyle(fullWidth: true) }

    /// 主要按钮样式（小尺寸）
    static var primarySmall: PrimaryButtonStyle { PrimaryButtonStyle(size: .small) }
}

extension ButtonStyle where Self == SecondaryButtonStyle {
    /// 次要按钮样式
    static var secondary: SecondaryButtonStyle { SecondaryButtonStyle() }

    /// 次要按钮样式（小尺寸）
    static var secondarySmall: SecondaryButtonStyle { SecondaryButtonStyle(size: .small) }
}

extension ButtonStyle where Self == GhostButtonStyle {
    /// 幽灵按钮样式
    static var ghost: GhostButtonStyle { GhostButtonStyle() }
}

extension ButtonStyle where Self == DestructiveButtonStyle {
    /// 危险按钮样式
    static var destructive: DestructiveButtonStyle { DestructiveButtonStyle() }
}

// MARK: - Preview

#Preview("Button Styles") {
    VStack(spacing: 20) {
        // Primary
        VStack(spacing: 8) {
            Text("Primary").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("保存") { }
                    .buttonStyle(.primary)
                Button("Small") { }
                    .buttonStyle(.primarySmall)
            }
            Button("开始复习") { }
                .buttonStyle(.primaryFullWidth)
        }

        Divider()

        // Secondary
        VStack(spacing: 8) {
            Text("Secondary").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("取消") { }
                    .buttonStyle(.secondary)
                Button("跳过") { }
                    .buttonStyle(.secondarySmall)
            }
        }

        Divider()

        // Ghost
        VStack(spacing: 8) {
            Text("Ghost").font(.caption).foregroundStyle(.secondary)
            Button("了解更多") { }
                .buttonStyle(.ghost)
        }

        Divider()

        // Destructive
        VStack(spacing: 8) {
            Text("Destructive").font(.caption).foregroundStyle(.secondary)
            Button("删除") { }
                .buttonStyle(.destructive)
        }

        Divider()

        // Disabled
        VStack(spacing: 8) {
            Text("Disabled").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 12) {
                Button("保存") { }
                    .buttonStyle(.primary)
                    .disabled(true)
                Button("取消") { }
                    .buttonStyle(.secondary)
                    .disabled(true)
            }
        }
    }
    .padding()
}
