//
//  AccessibilityExtensions.swift
//  SnapDrillUI
//
//  Created by NotBad Labs on 2026/01/03.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  无障碍支持扩展
//

import SwiftUI
import SnapDrillCore

// MARK: - View Extensions

extension View {
    /// 添加无障碍标签和提示
    ///
    /// - Parameters:
    ///   - label: 无障碍标签（描述元素是什么）
    ///   - hint: 无障碍提示（描述元素的作用）
    ///   - value: 无障碍值（元素的当前值）
    /// - Returns: 配置了无障碍属性的视图
    public func accessible(
        label: String,
        hint: String? = nil,
        value: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
    }
    
    /// 标记为无障碍按钮
    ///
    /// - Parameters:
    ///   - label: 按钮标签
    ///   - hint: 按钮提示
    /// - Returns: 配置为按钮的视图
    public func accessibleButton(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(.isButton)
    }
    
    /// 标记为无障碍标题
    ///
    /// - Parameter label: 标题文本
    /// - Returns: 配置为标题的视图
    public func accessibleHeader(_ label: String) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isHeader)
    }
    
    /// 标记为无障碍图片
    ///
    /// - Parameters:
    ///   - label: 图片描述
    ///   - isDecorative: 是否为装饰性图片（装饰性图片会被 VoiceOver 忽略）
    /// - Returns: 配置为图片的视图
    public func accessibleImage(
        label: String,
        isDecorative: Bool = false
    ) -> some View {
        self
            .accessibilityLabel(isDecorative ? "" : label)
            .accessibilityAddTraits(.isImage)
            .accessibilityHidden(isDecorative)
    }
    
    /// 组合多个元素为一个无障碍元素
    ///
    /// - Parameters:
    ///   - label: 组合后的标签
    ///   - children: 是否包含子元素
    /// - Returns: 组合后的视图
    public func accessibleGroup(
        label: String,
        combineChildren: Bool = true
    ) -> some View {
        self
            .accessibilityElement(children: combineChildren ? .combine : .contain)
            .accessibilityLabel(label)
    }
    
    /// 支持动态字体大小
    ///
    /// - Parameter category: 文本样式类别
    /// - Returns: 支持动态字体的视图
    public func dynamicTypeSize(_ category: DynamicTypeSize = .large) -> some View {
        self
            .dynamicTypeSize(...category)
    }
}

// MARK: - Accessibility Helpers

/// 无障碍辅助工具
public enum AccessibilityHelper {
    
    // MARK: - Public API
    
    /// 生成复习项目的无障碍标签
    ///
    /// - Parameters:
    ///   - content: 题目内容
    ///   - subject: 学科
    ///   - difficulty: 难度
    /// - Returns: 完整的无障碍标签
    public static func reviewItemLabel(
        content: String,
        subject: String,
        difficulty: Int
    ) -> String {
        let difficultyText = difficultyDescription(difficulty)
        return L10n.Accessibility.reviewItemLabel(subject: subject, difficulty: difficultyText, content: content)
    }

    /// 生成复习按钮的无障碍提示
    ///
    /// - Parameter count: 待复习数量
    /// - Returns: 无障碍提示文本
    public static func reviewButtonHint(count: Int) -> String {
        L10n.Accessibility.reviewButtonHint(count: count)
    }

    /// 生成导出按钮的无障碍提示
    ///
    /// - Parameter format: 导出格式
    /// - Returns: 无障碍提示文本
    public static func exportButtonHint(format: String) -> String {
        L10n.Accessibility.exportButtonHint(format: format)
    }

    /// 将难度数字转换为描述性文本
    ///
    /// - Parameter difficulty: 难度值 (1-5)
    /// - Returns: 难度描述
    public static func difficultyDescription(_ difficulty: Int) -> String {
        L10n.Accessibility.difficultyLevel(difficulty)
    }

    /// 生成进度的无障碍描述
    ///
    /// - Parameters:
    ///   - current: 当前进度
    ///   - total: 总数
    /// - Returns: 进度描述
    public static func progressDescription(current: Int, total: Int) -> String {
        let percentage = total > 0 ? Int(Double(current) / Double(total) * 100) : 0
        return L10n.Accessibility.progressDescription(current: current, total: total, percentage: percentage)
    }

    /// 生成日期的无障碍描述
    ///
    /// - Parameter date: 日期
    /// - Returns: 日期描述
    public static func dateDescription(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        // 跟随系统语言，不硬编码 zh_CN
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// MARK: - Dynamic Type Support

extension Font {
    /// 创建支持动态字体的自定义字体
    ///
    /// - Parameters:
    ///   - style: 文本样式
    ///   - weight: 字体粗细
    /// - Returns: 动态字体
    public static func dynamicFont(
        _ style: Font.TextStyle,
        weight: Font.Weight = .regular
    ) -> Font {
        return .system(style, design: .default, weight: weight)
    }
}

// MARK: - Accessibility Announcements

/// 无障碍公告
public struct AccessibilityAnnouncement {
    /// 发送无障碍公告
    ///
    /// - Parameters:
    ///   - message: 公告消息
    ///   - priority: 优先级
    public static func announce(
        _ message: String,
        priority: AccessibilityNotificationPriority = .default
    ) {
        // .announcement = 标准文本播报，不重置焦点
        // .screenChanged = 屏幕整体变化，会重置 VoiceOver 焦点到第一个元素
        let notification: UIAccessibility.Notification = priority == .high ? .screenChanged : .announcement
        UIAccessibility.post(notification: notification, argument: message)
    }
}

/// 无障碍通知优先级
public enum AccessibilityNotificationPriority {
    /// 标准优先级，使用 `announcement` 通知（播报文本，不重置焦点）
    case `default`
    /// 高优先级，使用 `screenChanged` 通知（播报文本并重置 VoiceOver 焦点）
    case high
}
