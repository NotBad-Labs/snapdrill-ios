//
//  StatisticsRow.swift
//  NotBad
//
//  统计行组件
//
//  单一职责：展示单个统计指标
//

import SwiftUI

// MARK: - Statistics Row

/// 统计行组件
///
/// 用于在个人中心展示统计数据，包含：
/// - 图标（带圆形背景）
/// - 标题
/// - 数值
struct StatisticsRow: View {
    
    // MARK: - Properties
    
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.md) {
            iconView
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Text(value)
                .font(.system(.body, design: .rounded, weight: .bold))
                .foregroundStyle(color)
        }
        .padding(.vertical, DesignTokens.Spacing.xs)
    }
    
    // MARK: - Icon View
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.12))
                .frame(width: DesignTokens.IconSize.md, height: DesignTokens.IconSize.md)
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

// MARK: - Preview

#Preview {
    List {
        StatisticsRow(
            icon: "books.vertical.fill",
            title: "总题目",
            value: "128",
            color: .blue
        )
        StatisticsRow(
            icon: "checkmark.seal.fill",
            title: "已掌握",
            value: "42",
            color: .green
        )
    }
}
