//
//  FormCard.swift
//  NotBad
//
//  通用表单卡片容器组件
//
//  单一职责：提供统一的表单卡片视觉样式
//

import SwiftUI

// MARK: - Form Card

/// 表单卡片容器
///
/// 提供标准化的表单视觉样式：
/// - 可选的标题 header
/// - 圆角背景
/// - 统一的间距和配色
struct FormCard<Content: View, Header: View>: View {
    
    // MARK: - Properties
    
    @ViewBuilder let content: () -> Content
    @ViewBuilder let header: () -> Header
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
            header()
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
                .padding(.horizontal, DesignTokens.Spacing.sm)
            
            content()
                .background(Color.semantic.secondaryBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md))
        }
    }
}

// MARK: - Convenience Initializer

extension FormCard where Header == EmptyView {
    /// 无标题的表单卡片
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        self.header = { EmptyView() }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        FormCard {
            Text("Content")
                .padding()
        } header: {
            Text("With Header")
        }
        
        FormCard {
            Text("No Header")
                .padding()
        }
    }
    .padding()
}
