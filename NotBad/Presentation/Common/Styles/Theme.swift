//
//  Theme.swift
//  NotBad
//
//  品牌色系与设计令牌定义
//

import SwiftUI

// MARK: - Brand Colors

/// 品牌色系扩展
extension Color {

    /// 品牌色系命名空间
    static let brand = BrandColors()

    /// 语义色系命名空间
    static let semantic = SemanticColors()
}

// MARK: - BrandColors

/// 品牌色系
struct BrandColors {

    /// 主色 - 蓝紫色 (#4275F9)
    let primary = Color("BrandPrimary")

    /// 辅助色 - 橙黄色 (#FFC766)
    let secondary = Color("BrandSecondary")

    /// 成功色 - 绿色 (#33C766)
    let success = Color("BrandSuccess")

    /// 警告色 - 橙色 (#FF9933)
    let warning = Color("BrandWarning")

    /// 错误色 - 红色 (#EF4C4C)
    let error = Color("BrandError")
}

// MARK: - SemanticColors

/// 语义色系
struct SemanticColors {

    /// 主背景色
    var background: Color { Color(uiColor: .systemBackground) }

    /// 次级背景色
    var secondaryBackground: Color { Color(uiColor: .secondarySystemBackground) }

    /// 第三级背景色
    var tertiaryBackground: Color { Color(uiColor: .tertiarySystemBackground) }

    /// 分组背景色
    var groupedBackground: Color { Color(uiColor: .systemGroupedBackground) }

    /// 主文本色
    var text: Color { Color(uiColor: .label) }

    /// 次级文本色
    var secondaryText: Color { Color(uiColor: .secondaryLabel) }

    /// 第三级文本色
    var tertiaryText: Color { Color(uiColor: .tertiaryLabel) }

    /// 占位文本色
    var placeholderText: Color { Color(uiColor: .placeholderText) }

    /// 分隔线颜色
    var separator: Color { Color(uiColor: .separator) }

    /// 不透明分隔线
    var opaqueSeparator: Color { Color(uiColor: .opaqueSeparator) }
}

// MARK: - Design Tokens

/// 设计令牌
enum DesignTokens {

    // MARK: - Spacing

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    // MARK: - Corner Radius

    enum CornerRadius {
        static let sm: CGFloat = 6
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let full: CGFloat = .infinity
    }

    // MARK: - Shadow

    enum Shadow {
        static let light = ShadowStyle(
            color: .black.opacity(0.05),
            radius: 4,
            x: 0,
            y: 2
        )

        static let medium = ShadowStyle(
            color: .black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 4
        )

        static let heavy = ShadowStyle(
            color: .black.opacity(0.15),
            radius: 16,
            x: 0,
            y: 8
        )
    }

    // MARK: - Animation

    enum Animation {
        static let fast: SwiftUI.Animation = .easeOut(duration: 0.15)
        static let standard: SwiftUI.Animation = .easeInOut(duration: 0.25)
        static let slow: SwiftUI.Animation = .easeInOut(duration: 0.4)
        static let spring: SwiftUI.Animation = .spring(response: 0.35, dampingFraction: 0.7)
    }

    // MARK: - Icon Size

    /// 图标/头像尺寸令牌
    enum IconSize {
        /// 超小图标 (24pt) - 列表项图标
        static let xs: CGFloat = 24
        /// 小图标 (32pt) - 紧凑型头像
        static let sm: CGFloat = 32
        /// 中小图标 (36pt) - 统计项图标
        static let md: CGFloat = 36
        /// 中等图标 (40pt) - 标准按钮图标
        static let lg: CGFloat = 40
        /// 较大图标 (44pt) - Touch Target 最小尺寸
        static let xl: CGFloat = 44
        /// 中大图标 (48pt) - 操作按钮图标
        static let xl2: CGFloat = 48
        /// 大图标 (56pt) - 主操作按钮
        static let xxl: CGFloat = 56
        /// 头像小 (64pt) - 用户头像
        static let avatarSm: CGFloat = 64
        /// 头像大 (80pt) - 详情页头像
        static let avatarLg: CGFloat = 80
        /// 特大 (100pt) - 编辑头像
        static let avatarXl: CGFloat = 100
    }
}

// MARK: - ShadowStyle

/// 阴影样式
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Typography

/// 字体样式（支持 Dynamic Type）
enum Typography {
    
    // MARK: - Display (大标题数字)
    
    /// 超大数字显示 (如统计数字)
    static func displayLarge(weight: Font.Weight = .bold, design: Font.Design = .rounded) -> Font {
        .system(.largeTitle, design: design, weight: weight)
    }
    
    /// 大数字显示
    static func displayMedium(weight: Font.Weight = .semibold, design: Font.Design = .rounded) -> Font {
        .system(.title, design: design, weight: weight)
    }
    
    /// 中等数字显示
    static func displaySmall(weight: Font.Weight = .medium, design: Font.Design = .rounded) -> Font {
        .system(.title2, design: design, weight: weight)
    }
    
    // MARK: - Icon Sizes (图标字号)
    
    /// 特大图标 (Onboarding/Empty State)
    static let iconXL: Font = .system(size: 80)
    
    /// 大图标
    static let iconLarge: Font = .system(size: 60)
    
    /// 中等图标
    static let iconMedium: Font = .system(size: 40)
    
    /// 小图标
    static let iconSmall: Font = .system(size: 28)
}

// MARK: - View Extension

extension View {

    /// 应用阴影样式
    func shadow(_ style: ShadowStyle) -> some View {
        shadow(color: style.color, radius: style.radius, x: style.x, y: style.y)
    }
}
