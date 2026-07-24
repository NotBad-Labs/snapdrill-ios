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
import UIKit

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    
    // MARK: - Properties
    
    @Binding var selectedItemIDs: Set<UUID>
    
    @Bindable var router: LibraryRouter
    @Bindable var viewModel: LibraryViewModel
    
    @Environment(\.editMode) private var editMode
    @Environment(\.profileManager) private var profileManager
    @ScaledMetric(relativeTo: .body) private var tabBarBreathingRoom: CGFloat = 110
    private let tabBarViewportClearance: CGFloat = 72
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
            searchSection

            // 主分类快速过滤器（主分类维度的值；全量维度过滤在 FilterSheet）
            if let categoryDim = viewModel.dimension(forSystemKey: CategorySystemKey.category) {
                Section {
                     ScrollView(.horizontal, showsIndicators: false) {
                         HStack(spacing: 12) {
                             ForEach(viewModel.valuesByDimension[categoryDim.id] ?? []) { value in
                                 let selected = viewModel.isFilterSelected(value.id, inDimension: categoryDim.id)
                                 Button {
                                     viewModel.toggleFilter(value.id, inDimension: categoryDim.id)
                                 } label: {
                                     Text(value.name)
                                         .font(.subheadline)
                                         .lineLimit(1)
                                         .fixedSize(horizontal: true, vertical: false)
                                         .padding(.horizontal, 14)
                                         .padding(.vertical, 8)
                                         .background(selected ? Color.blue : Color(.tertiarySystemFill))
                                         .foregroundStyle(selected ? Color.white : Color.primary)
                                         .clipShape(Capsule())
                                         .overlay {
                                             if !selected {
                                                 Capsule()
                                                     .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
                                             }
                                         }
                                 }
                                 .buttonStyle(.plain)
                                 .accessibleButton(label: L10n.Accessibility.filterCategory(value.name))
                                 .accessibilityIdentifier("library.quickFilter.\(value.name)")
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
            
            // 活跃过滤指示器：非主分类维度的选中值（主分类已在上方 capsule 展示），方便感知和快速清除
            let activeFilterChips = viewModel.selectedFilterValues
                .filter { $0.dimension?.systemKey != CategorySystemKey.category }
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
                                    .accessibilityIdentifier("library.activeFilter.remove.\(value.name)")
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
                            .accessibilityIdentifier("library.activeFilter.clear")
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if viewModel.filteredItems.isEmpty {
                if viewModel.searchText.isEmpty && viewModel.selectedValueIdsByDimension.isEmpty {
                    AccessibleEmptyState(
                        title: L10n.Library.noItems,
                        message: L10n.Library.noItemsHint,
                        systemImage: "books.vertical",
                        actionTitle: L10n.Dashboard.goCapture,
                        actionSystemImage: "camera.viewfinder"
                    ) {
                        NotificationCenter.default.post(name: .switchToCaptureTab, object: nil)
                    }
                } else {
                    AccessibleEmptyState(
                        title: L10n.Library.noSearchResults,
                        message: L10n.Library.noSearchResultsHint,
                        systemImage: "line.3.horizontal.decrease.circle",
                        actionTitle: L10n.Library.clearFilters,
                        actionSystemImage: "xmark.circle"
                    ) {
                        viewModel.resetFilters()
                    }
                }
            } else {
                ForEach(viewModel.filteredItems) { item in
                    // NavigationLink 提供标准 > 箭头和 VoiceOver 导航语义；
                    // List(selection:) 在 editMode 下自动禁用导航，无需手动 guard
                    NavigationLink(value: LibraryDestination.detail(item)) {
                        HStack(alignment: .center, spacing: 12) {
                            LibraryItemThumbnail(
                                imagePath: item.imagePath,
                                imageStorage: profileManager.activeImageStorage
                            )

                            VStack(alignment: .leading, spacing: 6) {
                                Text(item.content?.isEmpty == false ? item.content ?? "" : L10n.Library.noContent)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)

                                HStack(spacing: 8) {
                                    // 主分类标签：主分类维度值，无则取首个有值维度的首值
                                    LibraryCategoryChip(
                                        title: item.primaryCategoryName
                                            ?? item.categoryValuesByDimension.first?.values.first?.name
                                            ?? L10n.Library.noCategory,
                                        isPlaceholder: item.primaryCategoryName == nil
                                            && item.categoryValuesByDimension.first?.values.first == nil
                                    )

                                    Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(.vertical, 2)
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

            bottomBreathingRoom
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .padding(.bottom, tabBarViewportClearance)
        .accessibilityIdentifier("library.root")
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

    private var searchSection: some View {
        Section {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityHidden(true)

                TextField(
                    L10n.Library.searchPlaceholder,
                    text: Binding(
                        get: { viewModel.searchText },
                        set: { viewModel.searchText = $0 }
                    ),
                    axis: .vertical
                )
                .font(.body)
                .lineLimit(1...2)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .accessibilityIdentifier("library.searchField")

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.Library.clearFilters)
                    .accessibilityIdentifier("library.search.clear")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 52, alignment: .center)
            .background(Color(.secondarySystemGroupedBackground), in: Capsule())
        }
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }

    private var bottomBreathingRoom: some View {
        Color.clear
            .frame(height: tabBarBreathingRoom)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
    }
}

private struct LibraryItemThumbnail: View {
    let imagePath: String?
    let imageStorage: ImageStorage

    @State private var image: UIImage?
    @ScaledMetric(relativeTo: .body) private var scaledSize: CGFloat = 62

    private var size: CGFloat {
        min(max(scaledSize, 56), 78)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: imagePath == nil ? "doc.text" : "photo")
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: size, height: size)
        .background(Color(.tertiarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .contentShape(Rectangle())
        .accessibilityHidden(true)
        .task(id: imagePath) {
            image = nil
            guard let imagePath else {
                return
            }
            image = await imageStorage.loadDownsampledImageAsync(path: imagePath, maxLongSide: 240)
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
            .foregroundStyle(.primary)
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
