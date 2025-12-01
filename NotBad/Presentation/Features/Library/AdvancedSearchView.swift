//
//  AdvancedSearchView.swift
//  NotBad
//
//  Created by LIAOYIMING on 2025/6/5.
//

import SwiftUI
import SwiftData

// MARK: - AdvancedSearchView

/// 高级搜索视图
///
/// 提供多条件筛选功能，支持按学科、难度、掌握程度、日期等条件组合搜索。
struct AdvancedSearchView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Bindings

    /// 筛选条件
    @Binding var searchCriteria: SearchCriteria

    // MARK: - State

    /// 本地编辑的条件副本
    @State private var localCriteria: SearchCriteria

    // MARK: - Init

    init(searchCriteria: Binding<SearchCriteria>) {
        _searchCriteria = searchCriteria
        _localCriteria = State(initialValue: searchCriteria.wrappedValue)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                keywordSection
                subjectSection
                difficultySection
                masterySection
                dateSection
                otherConditionsSection
                resetSection
            }
            .navigationTitle("高级搜索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
        }
    }
}

// MARK: - Sections

extension AdvancedSearchView {
    /// 关键词搜索区域
    private var keywordSection: some View {
        Section("关键词") {
            TextField("搜索标题、笔记、知识点", text: $localCriteria.keyword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }

    /// 学科筛选区域
    private var subjectSection: some View {
        Section("学科") {
            SubjectSelectionGrid(selectedSubjects: $localCriteria.subjects)
        }
    }

    /// 难度筛选区域
    private var difficultySection: some View {
        Section("难度") {
            DifficultySelectionRow(selectedDifficulties: $localCriteria.difficulties)
        }
    }

    /// 掌握程度筛选区域
    private var masterySection: some View {
        Section("掌握程度") {
            MasterySelectionRow(selectedMasteries: $localCriteria.masteryLevels)
        }
    }

    /// 日期范围区域
    private var dateSection: some View {
        Section("创建日期") {
            DateRangeRow(dateRange: $localCriteria.dateRange)
        }
    }

    /// 其他条件区域
    private var otherConditionsSection: some View {
        Section("其他条件") {
            Toggle("仅显示待复习", isOn: $localCriteria.needsReviewOnly)
            Toggle("仅显示已逾期", isOn: $localCriteria.overdueOnly)
            Toggle("仅显示有图片", isOn: $localCriteria.hasImageOnly)
            Toggle("仅显示有笔记", isOn: $localCriteria.hasNoteOnly)
        }
    }

    /// 重置按钮区域
    private var resetSection: some View {
        Section {
            Button("重置所有条件", role: .destructive) {
                withAnimation {
                    localCriteria = SearchCriteria()
                }
            }
        }
    }
}

// MARK: - Toolbar

extension AdvancedSearchView {
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("取消") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("应用") {
                searchCriteria = localCriteria
                dismiss()
            }
            .fontWeight(.semibold)
        }
    }
}

// MARK: - Preview

#Preview {
    AdvancedSearchView(searchCriteria: .constant(SearchCriteria()))
}
