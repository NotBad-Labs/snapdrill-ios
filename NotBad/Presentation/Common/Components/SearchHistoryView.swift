//
//  SearchHistoryView.swift
//  NotBad
//
//  搜索历史视图组件
//

import SwiftUI

// MARK: - SearchHistoryView

/// 搜索历史视图
///
/// 显示用户的搜索历史记录，支持点击快速搜索和删除。
///
/// ## 功能特性
///
/// - 显示最近搜索记录
/// - 点击记录快速填充搜索框
/// - 滑动删除单条记录
/// - 一键清空所有历史
///
/// ## 使用示例
///
/// ```swift
/// SearchHistoryView { query in
///     searchText = query
/// }
/// ```
struct SearchHistoryView: View {
    
    // MARK: - Properties
    
    /// 搜索历史管理器
    @State private var historyManager = SearchHistoryManager.shared
    
    /// 选择搜索词的回调
    let onSelect: (String) -> Void
    
    // MARK: - Body
    
    var body: some View {
        if !historyManager.searchHistory.isEmpty {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                // 标题和清空按钮
                HStack {
                    Label {
                        Text("search_history_title")
                            .font(.subheadline.weight(.medium))
                    } icon: {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            historyManager.clearHistory()
                        }
                    } label: {
                        Text("search_history_clear")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // 历史记录列表（使用 FlowLayout 标签形式）
                FlowLayout(spacing: DesignTokens.Spacing.sm) {
                    ForEach(historyManager.searchHistory, id: \.self) { query in
                        SearchHistoryChip(
                            text: query,
                            onTap: {
                                onSelect(query)
                            },
                            onDelete: {
                                withAnimation(.spring(response: 0.3)) {
                                    historyManager.removeSearch(query)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
        }
    }
}

// MARK: - SearchHistoryChip

/// 搜索历史标签
///
/// 单个搜索历史记录的展示组件，支持点击和删除。
private struct SearchHistoryChip: View {
    
    /// 搜索文本
    let text: String
    
    /// 点击回调
    let onTap: () -> Void
    
    /// 删除回调
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.sm - 2) {
            Text(text)
                .font(.subheadline)
                .lineLimit(1)
            
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.quaternary, in: Capsule())
        .contentShape(Capsule())
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Preview

#Preview {
    VStack {
        SearchHistoryView { _ in
            // Handle selection
        }
        Spacer()
    }
}
