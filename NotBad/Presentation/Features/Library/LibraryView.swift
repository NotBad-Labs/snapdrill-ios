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
/// ## 功能特性
///
/// - 按学科筛选错题
/// - 搜索标题和知识点
/// - 滑动删除错题
/// - 导航到错题详情
///
/// ## 使用示例
///
/// ```swift
/// LibraryView()
///     .modelContainer(for: ReviewItem.self)
/// ```
///
/// ## 架构设计
///
/// 视图采用 MVVM 架构：
/// - 使用 `@Query` 从 SwiftData 获取数据
/// - 使用 `LibraryViewModel` 处理筛选和删除逻辑
/// - 子组件（FilterChip、ItemRow）保持独立可复用
struct LibraryView: View {

    // MARK: - Properties

    /// 所有错题数据（按创建时间倒序）
    @Query(sort: \ReviewItem.createdAt, order: .reverse)
    private var items: [ReviewItem]

    /// 数据上下文
    @Environment(\.modelContext) private var modelContext

    /// 视图模型
    @State private var viewModel = LibraryViewModel()
    
    /// 用户配置管理器（获取启用的学科）
    @StateObject private var profileManager = UserProfileManager.shared
    
    /// 程序化导航路径
    @State private var navigationPath = NavigationPath()
    
    /// 搜索是否激活
    @Environment(\.isSearching) private var isSearching

    // MARK: - Computed Properties

    /// 筛选后的错题列表
    private var filteredItems: [ReviewItem] {
        viewModel.filteredItems(from: items)
    }
    
    /// 用户启用的学科列表（按原始顺序排列）
    /// 如果用户没有选择任何学科，显示所有学科
    private var enabledSubjects: [Subject] {
        let enabled = Subject.allCases.filter { profileManager.enabledSubjects.contains($0) }
        return enabled.isEmpty ? Array(Subject.allCases) : enabled
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                    // 右上角编辑按钮
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
                    // 批量操作工具栏
                    if viewModel.isSelectionMode {
                        batchActionBar
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .sheet(isPresented: $viewModel.showAdvancedSearch) {
                    AdvancedSearchView(searchCriteria: $viewModel.advancedCriteria)
                }
                .onAppear {
                    viewModel.configure(with: modelContext)
                    Logger.ui.debug("LibraryView onAppear - 共 \(items.count) 条数据")
                }
        }
    }
}

// MARK: - Subviews

private extension LibraryView {

    /// 内容视图
    @ViewBuilder
    var contentView: some View {
        if items.isEmpty {
            // 完全没有数据 - 显示首次使用引导
            EmptyStateView.noItems {
                // 发送通知切换到录入页面
                NotificationCenter.default.post(name: .switchToCapture, object: nil)
            }
        } else {
            itemList
        }
    }

    /// 筛选栏（固定在搜索栏下方）
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 全部按钮
                FilterChip(
                    title: String(localized: "filter_all"),
                    isSelected: viewModel.selectedSubject == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectSubject(nil)
                    }
                }

                // 只显示用户启用的学科
                ForEach(enabledSubjects, id: \.self) { subject in
                    FilterChip(
                        title: subject.displayName,
                        isSelected: viewModel.selectedSubject == subject
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectSubject(subject)
                        }
                    }
                }
                
                // 分隔线
                Divider()
                    .frame(height: 20)
                
                // 排序按钮
                sortButton
                
                // 高级筛选按钮
                advancedFilterButton
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
    
    /// 排序按钮
    private var sortButton: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                Button {
                    withAnimation {
                        viewModel.sortOption = option
                    }
                } label: {
                    HStack {
                        Text(option.displayName)
                        if viewModel.sortOption == option {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.arrow.down")
                Text(viewModel.sortOption.shortName)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.semantic.tertiaryBackground, in: Capsule())
        }
    }
    
    /// 高级筛选按钮
    private var advancedFilterButton: some View {
        Button {
            viewModel.showAdvancedSearch = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "slider.horizontal.3")
                if viewModel.advancedCriteria.hasActiveFilters {
                    Text("\(viewModel.advancedCriteria.activeFilterCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.brand.primary, in: Capsule())
                }
            }
            .font(.subheadline)
            .foregroundStyle(viewModel.advancedCriteria.hasActiveFilters ? Color.brand.primary : .secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.semantic.tertiaryBackground, in: Capsule())
        }
    }

    /// 错题列表
    var itemList: some View {
        List {
            // 筛选栏（固定在顶部）
            Section {
                filterBar
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
            // 搜索历史（仅在搜索框为空且有历史记录时显示）
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
                    // 有数据但筛选结果为空
                    ContentUnavailableView {
                        Label(String(localized: "library_no_results"), systemImage: "magnifyingglass")
                    } description: {
                        Text("library_try_different_filter")
                    }
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredItems) { item in
                        if viewModel.isSelectionMode {
                            // 选择模式：点击切换选中状态
                            Button {
                                withAnimation(.spring(response: 0.2)) {
                                    viewModel.toggleSelection(for: item.id)
                                }
                            } label: {
                                HStack {
                                    Image(systemName: viewModel.isSelected(item.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundStyle(viewModel.isSelected(item.id) ? Color.brand.primary : .secondary)
                                    ItemRow(item: item)
                                }
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(viewModel.isSelected(item.id) ? Color.brand.primary.opacity(0.1) : Color.clear)
                        } else {
                            // 正常模式：点击导航到详情
                            Button {
                                navigationPath.append(item)
                            } label: {
                                ItemRow(item: item)
                            }
                            .buttonStyle(.plain)
                            // 添加右侧箭头，模拟 NavigationLink 外观
                            .listRowBackground(Color.clear)
                            .background(alignment: .trailing) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(.tertiary)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                    .onDelete { offsets in
                        withAnimation {
                            viewModel.deleteItems(from: filteredItems, at: offsets)
                        }
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: ReviewItem.self) { item in
            ItemDetailView(item: item)
        }
    }
    
    /// 批量操作工具栏
    var batchActionBar: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(spacing: 16) {
                // 选中数量提示
                Text(String(format: String(localized: "batch_selected_count"), viewModel.selectedCount))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                // 全选/取消全选
                Button {
                    withAnimation(.spring(response: 0.2)) {
                        if viewModel.selectedCount == filteredItems.count {
                            viewModel.deselectAll()
                        } else {
                            viewModel.selectAll(from: filteredItems)
                        }
                    }
                } label: {
                    Text(viewModel.selectedCount == filteredItems.count ? "batch_deselect_all" : "batch_select_all")
                        .font(.subheadline)
                }
                
                // 标记掌握度菜单
                Menu {
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.markSelectedItems(from: items, as: level)
                            }
                        } label: {
                            Label(level.displayName, systemImage: level.icon)
                        }
                    }
                } label: {
                    Label("batch_mark_mastery", systemImage: "checkmark.seal")
                        .font(.subheadline)
                }
                .disabled(viewModel.selectedCount == 0)
                
                // 删除按钮
                Button(role: .destructive) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.deleteSelectedItems(from: items)
                    }
                } label: {
                    Label("batch_delete", systemImage: "trash")
                        .font(.subheadline)
                }
                .disabled(viewModel.selectedCount == 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(.regularMaterial)
        }
    }
}

// MARK: - FilterChip

/// 筛选芯片组件
///
/// 用于学科筛选的可选中按钮组件。
///
/// ## 使用示例
///
/// ```swift
/// FilterChip(
///     title: "数学",
///     isSelected: selectedSubject == .math
/// ) {
///     selectedSubject = .math
/// }
/// ```
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
                .padding(.vertical, 12) // Increased vertical padding for better touch target
                .frame(minHeight: 44)   // Ensure minimum touch target height
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

// MARK: - ItemRow

/// 错题列表行组件
///
/// 展示错题的缩略图、标题、学科、掌握度和日期信息。
///
/// ## 性能优化
///
/// - 使用 `AsyncImage` 风格的懒加载避免主线程阻塞
/// - 缓存解码后的缩略图
///
/// ## 使用示例
///
/// ```swift
/// List(items) { item in
///     ItemRow(item: item)
/// }
/// ```
struct ItemRow: View {

    // MARK: - Properties

    /// 错题数据
    let item: ReviewItem
    
    /// 缓存的缩略图
    @State private var cachedThumbnail: UIImage?

    // MARK: - Constants

    /// 缩略图尺寸
    private enum Layout {
        static let thumbnailSize: CGFloat = 70
        static let cornerRadius: CGFloat = 12
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
            infoSection
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.title), \(item.subject.displayName), \(item.mastery.displayName)")
        .task(id: item.id) {
            // 异步加载缩略图，避免阻塞主线程
            await loadThumbnail()
        }
    }
    
    // MARK: - Thumbnail Loading
    
    /// 异步加载并缓存缩略图
    private func loadThumbnail() async {
        guard cachedThumbnail == nil,
              let data = item.imageData else { return }
        
        // 在后台线程解码和缩放图片
        let thumbnail = await Task.detached(priority: .userInitiated) {
            guard let original = UIImage(data: data) else { return nil as UIImage? }
            
            // 生成缩略图，避免加载全尺寸图片
            let targetSize = CGSize(width: Layout.thumbnailSize * 2, height: Layout.thumbnailSize * 2)
            let renderer = UIGraphicsImageRenderer(size: targetSize)
            return renderer.image { _ in
                original.draw(in: CGRect(origin: .zero, size: targetSize))
            }
        }.value
        
        await MainActor.run {
            cachedThumbnail = thumbnail
        }
    }
}

// MARK: - ItemRow Subviews

private extension ItemRow {

    /// 缩略图（使用缓存）
    @ViewBuilder
    var thumbnailView: some View {
        if let thumbnail = cachedThumbnail {
            Image(uiImage: thumbnail)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        } else if item.imageData != nil {
            // 有图片数据但还在加载中
            loadingThumbnail
        } else {
            placeholderThumbnail
        }
    }
    
    /// 加载中的缩略图
    var loadingThumbnail: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color.gray.opacity(0.1))
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .overlay {
                ProgressView()
                    .scaleEffect(0.8)
            }
    }

    /// 占位缩略图
    var placeholderThumbnail: some View {
        RoundedRectangle(cornerRadius: Layout.cornerRadius)
            .fill(Color.gray.opacity(0.1))
            .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
            .overlay {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
    }

    /// 信息区域
    var infoSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.title)
                .font(.headline)
                .lineLimit(2)

            HStack(spacing: 8) {
                subjectTag
                MasteryBadge(level: item.mastery)
                Spacer()
                dateLabel
            }
        }
    }

    /// 学科标签
    var subjectTag: some View {
        Text(item.subject.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(item.subject.color.opacity(0.1))
            .foregroundStyle(item.subject.color)
            .clipShape(Capsule())
    }

    /// 日期标签
    var dateLabel: some View {
        Text(item.createdAt, format: .dateTime.month().day())
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}

// MARK: - Preview

#Preview("Library View") {
    LibraryView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}

#Preview("Filter Chip") {
    HStack {
        FilterChip(title: "全部", isSelected: true) {}
        FilterChip(title: "数学", isSelected: false) {}
    }
    .padding()
}
