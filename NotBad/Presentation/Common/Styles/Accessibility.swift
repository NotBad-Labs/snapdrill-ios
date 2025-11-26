//
//  Accessibility.swift
//  NotBad
//
//  无障碍辅助扩展
//

import SwiftUI

// MARK: - View Accessibility Extensions

extension View {
    
    /// 标记为按钮并添加无障碍标签
    ///
    /// - Parameters:
    ///   - label: 无障碍标签（VoiceOver 朗读）
    ///   - hint: 无障碍提示（可选）
    /// - Returns: 添加无障碍特征的视图
    ///
    /// ## 使用示例
    /// ```swift
    /// Button(action: {}) {
    ///     Image(systemName: "plus")
    /// }
    /// .accessibleButton("添加错题", hint: "点击后进入拍照界面")
    /// ```
    func accessibleButton(_ label: String, hint: String? = nil) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 标记为图片并添加无障碍标签
    ///
    /// - Parameter label: 图片描述
    /// - Returns: 添加无障碍特征的视图
    func accessibleImage(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isImage)
    }
    
    /// 标记为标题
    ///
    /// - Parameter level: 标题级别（默认无指定级别）
    /// - Returns: 添加标题特征的视图
    func accessibleHeader() -> some View {
        self.accessibilityAddTraits(.isHeader)
    }
    
    /// 标记为静态文本（纯装饰性）
    ///
    /// - Returns: 对辅助技术隐藏的视图
    func accessibleDecorative() -> some View {
        self.accessibilityHidden(true)
    }
    
    /// 添加无障碍值
    ///
    /// - Parameters:
    ///   - value: 当前值
    ///   - label: 值的描述
    /// - Returns: 添加无障碍值的视图
    ///
    /// ## 使用示例
    /// ```swift
    /// ProgressView(value: 0.75)
    ///     .accessibleValue("75%", label: "完成进度")
    /// ```
    func accessibleValue(_ value: String, label: String? = nil) -> some View {
        self
            .accessibilityValue(value)
            .accessibilityLabel(label ?? "")
    }
    
    /// 组合多个元素为一个无障碍单元
    ///
    /// - Parameter label: 组合后的标签
    /// - Returns: 组合后的视图
    ///
    /// ## 使用示例
    /// ```swift
    /// HStack {
    ///     Image(systemName: "star.fill")
    ///     Text("128")
    ///     Text("错题")
    /// }
    /// .accessibleCombined("128道错题")
    /// ```
    func accessibleCombined(_ label: String) -> some View {
        self
            .accessibilityElement(children: .combine)
            .accessibilityLabel(label)
    }
    
    /// 忽略子元素的无障碍信息
    ///
    /// - Parameter label: 自定义标签
    /// - Returns: 忽略子元素的视图
    func accessibleIgnoreChildren(_ label: String) -> some View {
        self
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(label)
    }
}

// MARK: - Scaled Icon Sizes

/// 支持 Dynamic Type 的图标尺寸
///
/// 在视图中使用 @ScaledMetric 时参考这些基准值。
///
/// ## 使用示例
/// ```swift
/// struct MyView: View {
///     @ScaledMetric private var iconSize = IconSizeToken.large
///     
///     var body: some View {
///         Image(systemName: "star")
///             .font(.system(size: iconSize))
///     }
/// }
/// ```
enum IconSizeToken {
    /// 小图标（16pt）
    static let small: CGFloat = 16
    /// 中等图标（24pt）
    static let medium: CGFloat = 24
    /// 大图标（32pt）
    static let large: CGFloat = 32
    /// 超大图标（48pt）
    static let extraLarge: CGFloat = 48
    /// 巨大图标（64pt）
    static let huge: CGFloat = 64
}

// MARK: - Accessibility Announcements

/// 无障碍公告工具
@MainActor
enum AccessibilityAnnouncement {
    
    /// 发送无障碍公告
    ///
    /// - Parameter message: 要朗读的消息
    static func announce(_ message: String) {
        UIAccessibility.post(notification: .announcement, argument: message)
    }
    
    /// 发送屏幕变化通知
    ///
    /// - Parameter element: 新获得焦点的元素（可选）
    static func screenChanged(_ element: Any? = nil) {
        UIAccessibility.post(notification: .screenChanged, argument: element)
    }
    
    /// 发送布局变化通知
    ///
    /// - Parameter element: 新获得焦点的元素（可选）
    static func layoutChanged(_ element: Any? = nil) {
        UIAccessibility.post(notification: .layoutChanged, argument: element)
    }
}

// MARK: - Reduce Motion Support

extension View {
    
    /// 根据减少动态效果设置应用动画
    ///
    /// - Parameters:
    ///   - animation: 正常动画
    ///   - reducedAnimation: 减少动态效果时的动画
    ///   - value: 触发动画的值
    /// - Returns: 应用动画的视图
    func animationRespectingMotion<V: Equatable>(
        _ animation: Animation?,
        reduced reducedAnimation: Animation? = nil,
        value: V
    ) -> some View {
        self.modifier(ReducedMotionAnimationModifier(
            animation: animation,
            reducedAnimation: reducedAnimation,
            value: value
        ))
    }
}

/// 减少动态效果动画修饰器
private struct ReducedMotionAnimationModifier<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    let animation: Animation?
    let reducedAnimation: Animation?
    let value: V
    
    func body(content: Content) -> some View {
        content.animation(
            reduceMotion ? reducedAnimation : animation,
            value: value
        )
    }
}
