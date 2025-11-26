//
//  InfoCard.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI

// MARK: - InfoCard

/// 信息卡片组件
///
/// 用于展示错题详情的信息卡片。
///
/// ## 使用示例
///
/// ```swift
/// InfoCard(title: "标题", icon: "text.alignleft") {
///     Text("错题标题内容")
/// }
/// ```
struct InfoCard<Content: View>: View {
    
    // MARK: - Properties
    
    /// 卡片标题
    let title: String
    
    /// 图标名称
    let icon: String
    
    /// 卡片内容
    @ViewBuilder let content: Content
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
            Label(title, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .accessibilityAddTraits(.isHeader)
            
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DesignTokens.Spacing.lg)
        .background(Color.semantic.secondaryBackground)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.lg))
        .accessibilityElement(children: .contain)
    }
}

#Preview("Info Card") {
    InfoCard(title: "测试标题", icon: "star.fill") {
        Text("测试内容")
    }
    .padding()
}
