//
//  BatchActionBar.swift
//  NotBad
//
//  批量操作工具栏组件
//
//  单一职责：提供批量选择、标记、删除操作
//

import SwiftUI

// MARK: - Batch Action Bar

/// 批量操作工具栏组件
///
/// 显示在列表底部，提供：
/// - 选中数量显示
/// - 全选/取消全选
/// - 批量标记掌握度
/// - 批量删除
struct BatchActionBar: View {
    
    // MARK: - Properties
    
    /// 当前选中数量
    let selectedCount: Int
    
    /// 总数量
    let totalCount: Int
    
    /// 全选/取消全选回调
    let onToggleSelectAll: () -> Void
    
    /// 标记掌握度回调
    let onMarkMastery: (MasteryLevel) -> Void
    
    /// 删除回调
    let onDelete: () -> Void
    
    // MARK: - Computed Properties
    
    private var isAllSelected: Bool {
        selectedCount == totalCount && totalCount > 0
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: DesignTokens.Spacing.lg) {
                selectedCountLabel
                
                Spacer()
                
                selectAllButton
                masteryMenu
                deleteButton
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

// MARK: - Subviews

private extension BatchActionBar {
    
    /// 选中数量标签
    var selectedCountLabel: some View {
        Text(String(format: String(localized: "batch_selected_count"), selectedCount))
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    
    /// 全选/取消全选按钮
    var selectAllButton: some View {
        Button {
            withAnimation(.spring(response: 0.2)) {
                onToggleSelectAll()
            }
        } label: {
            Text(isAllSelected ? "batch_deselect_all" : "batch_select_all")
                .font(.subheadline)
        }
    }
    
    /// 掌握度菜单
    var masteryMenu: some View {
        Menu {
            ForEach(MasteryLevel.allCases, id: \.self) { level in
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        onMarkMastery(level)
                    }
                } label: {
                    Label(level.displayName, systemImage: level.icon)
                }
            }
        } label: {
            Label("batch_mark_mastery", systemImage: "checkmark.seal")
                .font(.subheadline)
        }
        .disabled(selectedCount == 0)
    }
    
    /// 删除按钮
    var deleteButton: some View {
        Button(role: .destructive) {
            withAnimation(.spring(response: 0.3)) {
                onDelete()
            }
        } label: {
            Label("batch_delete", systemImage: "trash")
                .font(.subheadline)
        }
        .disabled(selectedCount == 0)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()
        BatchActionBar(
            selectedCount: 3,
            totalCount: 10,
            onToggleSelectAll: {},
            onMarkMastery: { _ in },
            onDelete: {}
        )
    }
}
