//
//  FormRow.swift
//  NotBad
//
//  通用表单行组件
//
//  单一职责：提供统一的表单行布局样式
//

import SwiftUI

// MARK: - Form Row

/// 表单行组件
///
/// 提供标准化的表单行布局：
/// - 左侧标签
/// - 右侧内容
/// - 可选的分隔线
/// - 可调整的垂直对齐方式
struct FormRow<Label: View, Content: View>: View {
    
    // MARK: - Properties
    
    let isLast: Bool
    var alignment: VerticalAlignment = .center
    @ViewBuilder let label: () -> Label
    @ViewBuilder let content: () -> Content
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: alignment) {
                label()
                    .font(.body)
                Spacer()
                content()
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignTokens.Spacing.md)
            .padding(.vertical, DesignTokens.Spacing.md)
            
            if !isLast {
                Divider()
                    .padding(.leading, DesignTokens.Spacing.md)
            }
        }
    }
}

// MARK: - Convenience Initializers

extension FormRow where Content == EmptyView {
    /// 仅有标签的表单行（用于展示型内容）
    init(isLast: Bool = false, @ViewBuilder label: @escaping () -> Label) {
        self.isLast = isLast
        self.alignment = .center
        self.label = label
        self.content = { EmptyView() }
    }
}

extension FormRow where Label == Text {
    /// 简化的文本标签表单行
    init(_ title: LocalizedStringKey, isLast: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.isLast = isLast
        self.alignment = .center
        self.label = { Text(title) }
        self.content = content
    }
}

// MARK: - Preview

#Preview {
    FormCard {
        VStack(spacing: 0) {
            FormRow(isLast: false) {
                Text("Label 1")
            } content: {
                Text("Content 1")
            }
            
            FormRow("Simple Label", isLast: true) {
                Toggle("", isOn: .constant(true))
            }
        }
    } header: {
        Text("Form Section")
    }
    .padding()
}
