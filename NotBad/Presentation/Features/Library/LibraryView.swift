//
//  LibraryView.swift
//  NotBad
//
//  题库视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData
import OSLog
import ReviewKit

// MARK: - LibraryView

/// 题库视图
///
/// 展示所有错题的列表视图，支持按学科筛选和搜索功能。
///
/// ## 架构设计
///
/// 视图采用 MVVM + Clean Architecture：
/// - 通过 DependencyFactory 注入 ViewModel
/// - ViewModel 通过 Use Cases 获取数据
/// - 子组件独立可复用：FilterChip、ItemRow、LibraryFilterBar、BatchActionBar
struct LibraryView: View {

    // MARK: - Properties

    @Environment(\.dependencyFactory) private var dependencyFactory
    @Environment(\.router) private var router
    @State private var viewModel: LibraryViewModel?
    @StateObject private var profileManager = UserProfileManager.shared
    @State private var navigationPath = NavigationPath()
    @Environment(\.isSearching) private var isSearching

    // MARK: - Computed Properties
    
    /// 从 ViewModel 获取的错题列表
    private var items: [ReviewItem] {
        viewModel?.items ?? []
    }

    private var filteredItems: [ReviewItem] {
        viewModel?.filteredItems(from: items) ?? []
    }
    
    private var enabledSubjects: [Subject] {
        let enabled = Subject.allCases.filter { profileManager.enabledSubjects.contains($0) }
        return enabled.isEmpty ? Array(Subject.allCases) : enabled
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if let viewModel {
                    mainContent(viewModel: viewModel)
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationDestination(for: UUID.self) { itemId in
                // 通过 ViewModel 获取 item 详情视图
                ItemDetailViewWrapper(itemId: itemId)
            }
            .task {
                // 初始化 ViewModel 并加载数据
                if viewModel == nil, let factory = dependencyFactory {
                    viewModel = factory.makeLibraryViewModel()
                }
                await viewModel?.loadItems()
            }
        }
    }
    
    // MARK: - Main Content
    
    @ViewBuilder
    private func mainContent(viewModel: LibraryViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel
        
        contentView(viewModel: viewModel)
            .navigationTitle("library_title")
            .navigationBarTitleDisplayMode(.large)
            .searchable(
                text: $bindableViewModel.searchText,
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
                batchActionBarIfNeeded(viewModel: viewModel)
            }
            .sheet(isPresented: $bindableViewModel.showAdvancedSearch) {
                AdvancedSearchView(searchCriteria: $bindableViewModel.advancedCriteria)
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onChange(of: router.pendingItemDetailId) { _, newId in
                handleSpotlightNavigation(itemId: newId)
            }
    }
    
    // MARK: - Batch Action Bar
    
    @ViewBuilder
    private func batchActionBarIfNeeded(viewModel: LibraryViewModel) -> some View {
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
        navigationPath.append(item.id)
        router.pendingItemDetailId = nil
    }
}

// MARK: - Subviews

private extension LibraryView {

    @ViewBuilder
    func contentView(viewModel: LibraryViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if items.isEmpty {
            EmptyStateView.noItems {
                router.selectedTab = .capture
            }
        } else {
            itemList(viewModel: viewModel)
        }
    }

    func itemList(viewModel: LibraryViewModel) -> some View {
        @Bindable var bindableViewModel = viewModel
        
        return List {
            // 筛选栏
            Section {
                LibraryFilterBar(
                    enabledSubjects: enabledSubjects,
                    selectedSubject: viewModel.selectedSubject,
                    sortOption: $bindableViewModel.sortOption,
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
                    itemRows(viewModel: viewModel)
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
    
    func itemRows(viewModel: LibraryViewModel) -> some View {
        ForEach(filteredItems) { reviewItem in
            if viewModel.isSelectionMode {
                selectionRow(for: reviewItem, viewModel: viewModel)
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
    
    func selectionRow(for reviewItem: ReviewItem, viewModel: LibraryViewModel) -> some View {
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

// MARK: - ItemDetailViewWrapper

/// 详情视图包装器（通过 ID 获取并展示）
private struct ItemDetailViewWrapper: View {
    let itemId: UUID
    @Environment(\.dependencyFactory) private var dependencyFactory
    @State private var item: ReviewItem?
    
    var body: some View {
        Group {
            if let item {
                // 使用 ReviewItem 展示详情
                ItemDetailFromEntityView(item: item)
            } else {
                ProgressView()
            }
        }
        .task {
            // 通过 Use Case 获取单个 item
            if let factory = dependencyFactory {
                let useCase = factory.makeFetchReviewItemsUseCase()
                item = await useCase.execute(id: itemId)
            }
        }
    }
}

/// 从 ReviewItem 实体展示详情
private struct ItemDetailFromEntityView: View {
    let item: ReviewItem
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                }
                
                if !item.note.isEmpty {
                    Text(item.note)
                        .foregroundStyle(.secondary)
                }
                
                // 更多详情...
            }
            .padding()
        }
        .navigationTitle(item.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Preview

#Preview("Library View") {
    LibraryView()
}