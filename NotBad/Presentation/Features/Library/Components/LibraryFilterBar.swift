//
//  LibraryFilterBar.swift
//  NotBad
//
//  题库筛选栏组件
//
//  单一职责：提供学科筛选、排序、高级筛选入口
//

import SwiftUI

// MARK: - Library Filter Bar

/// 题库筛选栏组件
///
/// 水平滚动的筛选栏，包含：
/// - 学科筛选芯片
/// - 排序选项菜单
/// - 高级筛选按钮
struct LibraryFilterBar: View {
    
    // MARK: - Properties
    
    /// 启用的学科列表
    let enabledSubjects: [Subject]
    
    /// 当前选中的学科
    let selectedSubject: Subject?
    
    /// 当前排序选项
    @Binding var sortOption: SortOption
    
    /// 高级筛选条件
    let advancedCriteria: SearchCriteria
    
    /// 学科选择回调
    let onSubjectSelected: (Subject?) -> Void
    
    /// 显示高级筛选回调
    let onShowAdvancedSearch: () -> Void
    
    // MARK: - Body
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignTokens.Spacing.md - 2) {
                allSubjectsChip
                subjectChips
                
                Divider()
                    .frame(height: 20)
                
                sortButton
                advancedFilterButton
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Subviews

private extension LibraryFilterBar {
    
    /// "全部"筛选芯片
    var allSubjectsChip: some View {
        FilterChip(
            title: String(localized: "filter_all"),
            isSelected: selectedSubject == nil
        ) {
            withAnimation(.spring(response: 0.3)) {
                onSubjectSelected(nil)
            }
        }
    }
    
    /// 学科筛选芯片
    var subjectChips: some View {
        ForEach(enabledSubjects, id: \.self) { subject in
            FilterChip(
                title: subject.displayName,
                isSelected: selectedSubject == subject
            ) {
                withAnimation(.spring(response: 0.3)) {
                    onSubjectSelected(subject)
                }
            }
        }
    }
    
    /// 排序按钮
    var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    withAnimation {
                        sortOption = option
                    }
                } label: {
                    HStack {
                        Text(option.displayName)
                        if sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "arrow.up.arrow.down")
                Text(sortOption.shortName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.semantic.tertiaryBackground, in: Capsule())
        }
    }
    
    /// 高级筛选按钮
    var advancedFilterButton: some View {
        Button(action: onShowAdvancedSearch) {
            HStack(spacing: DesignTokens.Spacing.xs) {
                Image(systemName: "slider.horizontal.3")
                if advancedCriteria.hasActiveFilters {
                    Text("\(advancedCriteria.activeFilterCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brand.primary, in: Capsule())
                }
            }
            .font(.subheadline)
            .foregroundStyle(advancedCriteria.hasActiveFilters ? Color.brand.primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.semantic.tertiaryBackground, in: Capsule())
        }
    }
}

// MARK: - Preview

#Preview {
    LibraryFilterBar(
        enabledSubjects: Subject.allCases.prefix(3).map { $0 },
        selectedSubject: Subject.math,
        sortOption: .constant(SortOption.createdAtDesc),
        advancedCriteria: SearchCriteria(),
        onSubjectSelected: { _ in },
        onShowAdvancedSearch: {}
    )
}
