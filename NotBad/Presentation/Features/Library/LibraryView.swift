//
//  LibraryView.swift
//  NotBad
//
//  题库视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

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

    // MARK: - Computed Properties

    /// 筛选后的错题列表
    private var filteredItems: [ReviewItem] {
        viewModel.filteredItems(from: items)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("library_title")
                .navigationBarTitleDisplayMode(.large)
                .searchable(text: $viewModel.searchText, prompt: Text("library_search_prompt"))
                .sheet(isPresented: $viewModel.showAdvancedSearch) {
                    AdvancedSearchView(searchCriteria: $viewModel.advancedCriteria)
                }
                .onAppear {
                    viewModel.configure(with: modelContext)
                    #if DEBUG
                    print("📚 [LibraryView] onAppear - 共 \(items.count) 条数据")
                    for item in items {
                        print("  📝 \(item.id): \(item.title)")
                    }
                    #endif
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
            // 完全没有数据
            ContentUnavailableView {
                Label(String(localized: "library_empty_title"), systemImage: "books.vertical")
            } description: {
                Text("library_empty_description")
            }
        } else {
            itemList
        }
    }

    /// 筛选栏（固定在搜索栏下方）
    var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                // 学科筛选
                FilterChip(
                    title: String(localized: "filter_all"),
                    isSelected: viewModel.selectedSubject == nil
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.selectSubject(nil)
                    }
                }

                ForEach(Subject.allCases, id: \.self) { subject in
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
            // 筛选栏作为列表第一个 section，随内容滚动
            Section {
                filterBar
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            
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
                        NavigationLink(value: item) {
                            ItemRow(item: item)
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
                .padding(.vertical, 8)
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
    }
}

// MARK: - ItemRow Subviews

private extension ItemRow {

    /// 缩略图
    @ViewBuilder
    var thumbnailView: some View {
        if let data = item.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Layout.thumbnailSize, height: Layout.thumbnailSize)
                .clipShape(RoundedRectangle(cornerRadius: Layout.cornerRadius))
        } else {
            placeholderThumbnail
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
