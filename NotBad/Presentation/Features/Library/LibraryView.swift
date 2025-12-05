//
//  LibraryView.swift
//  NotBad
//
//  题库视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData
import OSLog

// MARK: - LibraryView

/// 题库视图
///
/// 展示所有错题的列表视图，支持按学科筛选和搜索功能。
///
/// ## 架构设计
///
/// 视图采用 MVVM + 组件化架构：
/// - 使用 `@Query` 从 SwiftData 获取 ReviewItemModel
/// - 通过 ReviewItemMapper 转换为领域实体 ReviewItem
/// - 使用 `LibraryViewModel` 处理筛选和删除逻辑
/// - 子组件独立可复用：FilterChip、ItemRow、LibraryFilterBar、BatchActionBar
struct LibraryView: View {

    // MARK: - Properties

    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var models: [ReviewItemModel]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.router) private var router
    @State private var viewModel = LibraryViewModel()
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var navigationPath = NavigationPath()
    @Environment(\.isSearching) private var isSearching
    
    /// 将持久化模型转换为领域实体
    private var items: [ReviewItem] {
        models.map { ReviewItemMapper.toEntity(from: $0) }
    }

    // MARK: - Computed Properties

    private var filteredItems: [ReviewItem] {
        viewModel.filteredItems(from: items)
    }
    
    private var enabledSubjects: [Subject] {
        let enabled = Subject.allCases.filter { profileManager.enabledSubjects.contains($0) }
        return enabled.isEmpty ? Array(Subject.allCases) : enabled
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            mainContent
                .navigationDestination(for: UUID.self) { itemId in
                    if let model = models.first(where: { $0.id == itemId }) {
                        ItemDetailView(model: model)
                    }
                }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private var mainContent: some View {
        contentView
            .navigationTitle("library_title")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("library_search_prompt")
            )
            .onSubmit(of: .search) {
                viewModel.submitSearch()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if !items.isEmpty {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.toggleSelectionMode()
                            }
                        } label: {
                            Text(viewModel.isSelectionMode ? "library_done" : "library_edit")
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                batchActionBarIfNeeded
            }
            .sheet(isPresented: $viewModel.showAdvancedSearch) {
                AdvancedSearchView(searchCriteria: $viewModel.advancedCriteria)
            }
            .onAppear {
                viewModel.configure(with: modelContext)
                Logger.ui.debug("LibraryView onAppear - 共 \(items.count) 条数据")
            }
            .onChange(of: router.pendingItemDetailId) { _, newId in
                handleSpotlightNavigation(itemId: newId)
            }
    }
    
    // MARK: - Batch Action Bar
    
    @ViewBuilder
    private var batchActionBarIfNeeded: some View {
        if viewModel.isSelectionMode {
            BatchActionBar(
                selectedCount: viewModel.selectedCount,
                totalCount: filteredItems.count,
                onToggleSelectAll: {
                    if viewModel.selectedCount == filteredItems.count {
                        viewModel.deselectAll()
                    } else {
                        viewModel.selectAll(from: filteredItems)
                    }
                },
                onMarkMastery: { level in
                    viewModel.markSelectedItems(from: items, as: level)
                },
                onDelete: {
                    viewModel.deleteSelectedItems(from: items)
                }
            )
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
    
    // MARK: - Spotlight Navigation
    
    private func handleSpotlightNavigation(itemId: UUID?) {
        guard let itemId,
              let item = items.first(where: { $0.id == itemId }) else {
            return
        }
        navigationPath.append(item)
        router.pendingItemDetailId = nil
    }
}

// MARK: - Subviews

private extension LibraryView {

    @ViewBuilder
    var contentView: some View {
        if items.isEmpty {
            EmptyStateView.noItems {
                router.selectedTab = .capture
            }
        } else {
            itemList
        }
    }

    var itemList: some View {
        List {
            // 筛选栏
            Section {
                LibraryFilterBar(
                    enabledSubjects: enabledSubjects,
                    selectedSubject: viewModel.selectedSubject,
                    sortOption: $viewModel.sortOption,
                    advancedCriteria: viewModel.advancedCriteria,
                    onSubjectSelected: { viewModel.selectSubject($0) },
                    onShowAdvancedSearch: { viewModel.showAdvancedSearch = true }
                )
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            // 搜索历史
            if viewModel.searchText.isEmpty && !isSearching {
                Section {
                    SearchHistoryView { query in
                        viewModel.selectFromHistory(query)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            
            // 错题内容
            Section {
                if filteredItems.isEmpty {
                    noResultsView
                } else {
                    itemRows
                }
            }
        }
        .listStyle(.plain)
    }
    
    var noResultsView: some View {
        ContentUnavailableView {
            Label(String(localized: "library_no_results"), systemImage: "magnifyingglass")
        } description: {
            Text("library_try_different_filter")
        }
        .listRowSeparator(.hidden)
    }
    
    var itemRows: some View {
        ForEach(filteredItems) { reviewItem in
            if viewModel.isSelectionMode {
                selectionRow(for: reviewItem)
            } else {
                navigationRow(for: reviewItem)
            }
        }
        .onDelete { offsets in
            withAnimation {
                viewModel.deleteItems(from: filteredItems, at: offsets)
            }
        }
    }
    
    func selectionRow(for reviewItem: ReviewItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.2)) {
                viewModel.toggleSelection(for: reviewItem.id)
            }
        } label: {
            HStack {
                Image(systemName: viewModel.isSelected(reviewItem.id) ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(viewModel.isSelected(reviewItem.id) ? Color.brand.primary : .secondary)
                ItemRow(reviewItem: reviewItem)
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(viewModel.isSelected(reviewItem.id) ? Color.brand.primary.opacity(0.1) : Color.clear)
    }
    
    func navigationRow(for reviewItem: ReviewItem) -> some View {
        Button {
            navigationPath.append(reviewItem.id)
        } label: {
            ItemRow(reviewItem: reviewItem)
        }
        .buttonStyle(.plain)
        .listRowBackground(Color.clear)
        .background(alignment: .trailing) {
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .padding(.trailing, 4)
        }
    }
}

// MARK: - Preview

#Preview("Library View") {
    LibraryView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}