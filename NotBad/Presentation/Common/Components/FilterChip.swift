//
//  FilterChip.swift
//  NotBad
//
//  筛选芯片组件
//
//  单一职责：学科筛选的可选中按钮
//

import SwiftUI

// MARK: - Filter Chip

/// 筛选芯片组件
///
/// 用于学科筛选的可选中按钮组件。
/// 支持选中/未选中状态切换，带渐变背景和阴影效果。
struct FilterChip: View {
    
    // MARK: - Properties
    
    /// 显示标题
    let title: String
    
    /// 是否选中
    let isSelected: Bool
    
    /// 点击回调
    let action: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .frame(minHeight: 44)  // 确保最小触摸目标高度
                .background(backgroundGradient)
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(
                    color: isSelected ? .blue.opacity(0.3) : .clear,
                    radius: 4,
                    y: 2
                )
        }
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(isSelected ? "Double tap to deselect" : "Double tap to filter by this subject")
    }
    
    // MARK: - Private
    
    /// 背景渐变
    private var backgroundGradient: some ShapeStyle {
        if isSelected {
            LinearGradient(
                colors: [.blue, .blue.opacity(0.8)],
                startPoint: .leading,
                endPoint: .trailing
            )
        } else {
            LinearGradient(
                colors: [Color(uiColor: .secondarySystemBackground)],
                startPoint: .leading,
                endPoint: .trailing
            )
        }
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 12) {
        FilterChip(title: "全部", isSelected: true) {}
        FilterChip(title: "数学", isSelected: false) {}
        FilterChip(title: "语文", isSelected: false) {}
    }
    .padding()
}
