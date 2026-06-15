//
//  LibraryListView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  资料列表视图，展示特定筛选条件下的归档条目。
//

import SwiftUI
import SwiftData
import SnapDrillCore
import SnapDrillData
import SnapDrillUI

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    
    // MARK: - Properties
    
    @Binding var selectedItemIDs: Set<UUID>
    
    @Bindable var router: LibraryRouter
    @Bindable var viewModel: LibraryViewModel
    
    @Environment(\.editMode) private var editMode
    @State private var swipeDeleteIDs: Set<UUID> = []
    @State private var showSwipeDeleteConfirm = false

    init(
        selectedItemIDs: Binding<Set<UUID>>,
        router: LibraryRouter,
        viewModel: LibraryViewModel
    ) {
        self._selectedItemIDs = selectedItemIDs
        self.router = router
        self.viewModel = viewModel
    }
    
    // MARK: - Body
    
    var body: some View {
        List(selection: $selectedItemIDs) {
            // 学科快速过滤器（学科维度的值；全量维度过滤在 FilterSheet）
            if let subjectDim = viewModel.dimension(forSystemKey: CategorySystemKey.subject) {
                Section {
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack(spacing: 12) {
                             ForEach(viewModel.valuesByDimension[subjectDim.id] ?? []) { value in
                                 let selected = viewModel.isFilterSelected(value.id, inDimension: subjectDim.id)
                                 Button {
                                     viewModel.toggleFilter(value.id, inDimension: subjectDim.id)
                                 } label: {
                                     Text(value.name)
                                         .font(.subheadline)
                                         .padding(.horizontal, 14)
                                         .padding(.vertical, 7)
                                         .background(selected ? Color.blue : Color(.secondarySystemGroupedBackground))
                                         .foregroundStyle(selected ? Color.white : Color.primary)
                                         .clipShape(Capsule())
                                 }
                                 .buttonStyle(.plain)
                                 .accessibleButton(label: L10n.Accessibility.filterSubject(value.name))
                                 .accessibilityAddTraits(selected ? .isSelected : [])
                             }
                         }
                         .padding(.horizontal, 4)
                         .padding(.vertical, 8)
                     }
                     .listRowInsets(EdgeInsets())
                     .listRowBackground(Color.clear)
                }
            }
            
            // 活跃过滤指示器：非学科维度的选中值（学科已在上方 capsule 展示），方便感知和快速清除
            let activeFilterChips = viewModel.selectedFilterValues
                .filter { $0.dimension?.systemKey != CategorySystemKey.subject }
            if !activeFilterChips.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(activeFilterChips) { value in
                                HStack(spacing: 4) {
                                    Text(value.name)
                                        .font(.caption)
                                    Button {
                                        if let dimId = value.dimension?.id {
                                            viewModel.toggleFilter(value.id, inDimension: dimId)
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                    .accessibleButton(label: L10n.Accessibility.removeTagFilter(value.name))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            }
                            Button(L10n.Library.clearFilters) {
                                viewModel.clearValueFilters()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if viewModel.filteredItems.isEmpty {
                if viewModel.searchText.isEmpty && viewModel.selectedValueIdsByDimension.isEmpty && viewModel.selectedDifficulties.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.Library.noItems, systemImage: "books.vertical")
                    } description: {
                        Text(L10n.Library.noItemsHint)
                    } actions: {
                        Button(L10n.Dashboard.goCapture) {
                            NotificationCenter.default.post(name: .switchToCaptureTab, object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView {
                        Label(L10n.Library.noSearchResults, systemImage: "line.3.horizontal.decrease.circle")
                    } description: {
                        Text(L10n.Library.noSearchResultsHint)
                    } actions: {
                        Button(L10n.Library.clearFilters) {
                            viewModel.resetFilters()
                        }
                        .buttonStyle(.bordered)
                    }
                }
            } else {
                ForEach(viewModel.filteredItems) { item in
                    // NavigationLink 提供标准 > 箭头和 VoiceOver 导航语义；
                    // List(selection:) 在 editMode 下自动禁用导航，无需手动 guard
                    NavigationLink(value: LibraryDestination.detail(item)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.content?.isEmpty == false ? item.content ?? "" : L10n.Library.noContent)
                                .font(.headline)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)

                            HStack(spacing: 8) {
                                // 主分类标签：学科维度值，无则取首个有值维度的首值
                                LibraryCategoryChip(
                                    title: item.subjectCategoryName
                                        ?? item.categoryValuesByDimension.first?.values.first?.name
                                        ?? L10n.Library.noCategory,
                                    isPlaceholder: item.subjectCategoryName == nil
                                        && item.categoryValuesByDimension.first?.values.first == nil
                                )

                                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    // 长按进入多选模式（iOS 标准交互）
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                            withAnimation { editMode?.wrappedValue = .active }
                        }
                    )
                    .accessibilityHint(L10n.Accessibility.longPressToSelect)
                    .listRowBackground(Rectangle().fill(Color(.secondarySystemGroupedBackground)))
                    .listRowSeparator(.hidden)
                    .tag(item.id)
                }
                .onDelete { offsets in
                    // SnapDrill 无回收站，删除不可逆，需确认
                    swipeDeleteIDs = Set(offsets.compactMap { index in
                        viewModel.filteredItems.indices.contains(index) ? viewModel.filteredItems[index].id : nil
                    })
                    showSwipeDeleteConfirm = true
                }
                .deleteDisabled(editMode?.wrappedValue.isEditing == true)
                
                // 无限滚动触发器
                if viewModel.hasMore {
                    HStack(spacing: 8) {
                        Spacer()
                        ProgressView()
                            .controlSize(.small)
                        Text(L10n.Library.loadingMore)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .accessibilityElement(children: .combine)
                        .onAppear {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listRowSpacing(12)
        .confirmationDialog(L10n.Library.deleteConfirmTitle, isPresented: $showSwipeDeleteConfirm, titleVisibility: .visible) {
            Button(L10n.Common.delete, role: .destructive) {
                viewModel.softDeleteItems(ids: swipeDeleteIDs)
                swipeDeleteIDs.removeAll()
            }
            Button(L10n.Common.cancel, role: .cancel) {
                swipeDeleteIDs.removeAll()
            }
        } message: {
            Text(L10n.Library.deleteConfirmMessage)
        }
    }
}

private struct LibraryCategoryChip: View {
    let title: String
    let isPlaceholder: Bool

    var body: some View {
        Text(title)
            .font(.caption2.bold())
            .lineLimit(1)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .frame(minWidth: 42)
            .background(isPlaceholder ? Color.secondary.opacity(0.12) : Color.blue.opacity(0.1))
            .foregroundStyle(isPlaceholder ? Color.secondary : Color.blue)
            .clipShape(Capsule())
    }
}

#Preview {
    let schema = Schema(SnapDrillSchemaV1.models)
    // swiftlint:disable:next force_try
    let container = try! ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    let repos = RepositoryContainer(modelContext: container.mainContext)
    LibraryListView(
        selectedItemIDs: .constant([]),
        router: LibraryRouter(),
        viewModel: LibraryViewModel(repositories: repos)
    )
    .modelContainer(container)
}
