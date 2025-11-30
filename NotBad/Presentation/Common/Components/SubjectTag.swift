//
//  SubjectTag.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - SubjectTagStyle

/// 学科标签样式
enum SubjectTagStyle: Sendable {
    /// 紧凑 - 仅显示名称
    case compact

    /// 标准 - 图标 + 名称
    case standard

    /// 详细 - 图标 + 名称 + 数量
    case detailed

    /// 图标 - 仅图标
    case iconOnly
}

// MARK: - SubjectTag

/// 学科标签组件
///
/// 显示学科信息的可视化标签。
///
/// ## 功能特性
///
/// - 多种显示样式：紧凑、标准、详细、仅图标
/// - 选中状态支持
/// - 动画效果
///
/// ## 使用示例
///
/// ```swift
/// // 标准样式
/// SubjectTag(subject: .math)
///
/// // 带数量
/// SubjectTag(subject: .chinese, style: .detailed, count: 15)
///
/// // 选中状态
/// SubjectTag(subject: .english, isSelected: true)
/// ```
struct SubjectTag: View {

    // MARK: - Properties

    /// 学科
    let subject: Subject

    /// 显示样式
    var style: SubjectTagStyle = .standard

    /// 错题数量（详细样式时使用）
    var count: Int?

    /// 是否选中
    var isSelected: Bool = false

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            if style != .compact {
                iconView
            }

            if style != .iconOnly {
                textView
            }

            if style == .detailed, let count {
                countBadge(count)
            }
        }
        .padding(.horizontal, style == .compact ? DesignTokens.Spacing.sm : (style == .iconOnly ? DesignTokens.Spacing.xs : DesignTokens.Spacing.md))
        .padding(.vertical, style == .compact ? DesignTokens.Spacing.xs : (style == .iconOnly ? DesignTokens.Spacing.xs : DesignTokens.Spacing.xs))
        .background(backgroundStyle)
        .foregroundStyle(foregroundStyle)
        .clipShape(style == .iconOnly ? AnyShape(Circle()) : AnyShape(Capsule()))
        .shadow(
            color: isSelected ? subject.color.opacity(0.3) : .clear,
            radius: 4,
            y: 2
        )
    }

    // MARK: - Subviews

    private var iconView: some View {
        Image(systemName: subject.icon)
            .font(style == .iconOnly ? .subheadline : .caption)
    }

    private var textView: some View {
        Text(subject.displayName)
            .font(style == .compact ? .caption2 : .caption)
            .fontWeight(isSelected ? .semibold : .regular)
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .padding(.horizontal, DesignTokens.Spacing.xs)
            .padding(.vertical, 2)
            .background(isSelected ? .white.opacity(0.3) : subject.color.opacity(0.2))
            .clipShape(Capsule())
    }

    // MARK: - Styling

    private var backgroundStyle: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(subject.color.gradient)
        } else {
            AnyShapeStyle(subject.color.opacity(0.1))
        }
    }

    private var foregroundStyle: Color {
        isSelected ? .white : subject.color
    }
}

// MARK: - SelectableSubjectTag

/// 可选择的学科标签
///
/// 带有点击选择功能的学科标签。
struct SelectableSubjectTag: View {

    // MARK: - Properties

    /// 学科
    let subject: Subject

    /// 选中状态绑定
    @Binding var isSelected: Bool

    /// 错题数量
    var count: Int?

    /// 样式
    var style: SubjectTagStyle = .standard

    // MARK: - Body

    var body: some View {
        Button {
            withAnimation(DesignTokens.Animation.spring) {
                isSelected.toggle()
            }
        } label: {
            SubjectTag(
                subject: subject,
                style: count != nil ? .detailed : style,
                count: count,
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - SubjectTagGroup

/// 学科标签组
///
/// 显示多个学科标签，支持单选或多选。
struct SubjectTagGroup: View {

    // MARK: - Properties

    /// 可选学科列表
    let subjects: [Subject]

    /// 选中的学科
    @Binding var selection: Set<Subject>

    /// 是否单选模式
    var singleSelection: Bool = false

    /// 各学科数量
    var counts: [Subject: Int] = [:]

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                ForEach(subjects, id: \.self) { subject in
                    tagButton(for: subject)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Subviews

    private func tagButton(for subject: Subject) -> some View {
        let isSelected = selection.contains(subject)

        return Button {
            withAnimation(DesignTokens.Animation.spring) {
                if singleSelection {
                    selection = isSelected ? [] : [subject]
                } else {
                    if isSelected {
                        selection.remove(subject)
                    } else {
                        selection.insert(subject)
                    }
                }
            }
        } label: {
            SubjectTag(
                subject: subject,
                style: counts[subject] != nil ? .detailed : .standard,
                count: counts[subject],
                isSelected: isSelected
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Preview

#Preview("Subject Tags") {
    VStack(spacing: 16) {
        // Compact
        HStack {
            ForEach(Subject.coreSubjects, id: \.self) { subject in
                SubjectTag(subject: subject, style: .compact)
            }
        }

        // Standard
        HStack {
            ForEach(Subject.coreSubjects, id: \.self) { subject in
                SubjectTag(subject: subject, style: .standard)
            }
        }

        // Icon Only
        HStack {
            ForEach(Subject.coreSubjects, id: \.self) { subject in
                SubjectTag(subject: subject, style: .iconOnly)
            }
        }

        // Detailed
        HStack {
            SubjectTag(subject: .math, style: .detailed, count: 15)
            SubjectTag(subject: .chinese, style: .detailed, count: 8)
            SubjectTag(subject: .english, style: .detailed, count: 12)
        }

        // Selected
        HStack {
            SubjectTag(subject: .math, style: .standard, isSelected: true)
            SubjectTag(subject: .physics, style: .standard, isSelected: false)
        }
    }
    .padding()
}

#Preview("Selectable Tags") {
    struct PreviewWrapper: View {
        @State private var selected = false

        var body: some View {
            SelectableSubjectTag(
                subject: .math,
                isSelected: $selected,
                count: 10
            )
        }
    }
    return PreviewWrapper()
}

#Preview("Tag Group") {
    struct PreviewWrapper: View {
        @State private var selection: Set<Subject> = [.math]

        var body: some View {
            SubjectTagGroup(
                subjects: Subject.coreSubjects,
                selection: $selection,
                counts: [.math: 15, .chinese: 8, .english: 12]
            )
        }
    }
    return PreviewWrapper()
}
