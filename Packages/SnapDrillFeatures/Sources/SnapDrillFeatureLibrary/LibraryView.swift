//
//  LibraryView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/29.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库列表界面，支持题目浏览和筛选
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// 题库列表界面
public struct LibraryView: View {
    
    // MARK: - Properties
    
    @Bindable private var router: LibraryRouter
    @Environment(\.repositories) private var repositories

    @State private var viewModel: LibraryViewModel?
    
    // 原生选择状态
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var isExportSheetPresented = false
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteConfirmation = false
    @State private var isFilterPresented = false
    @State private var isFirstAppear = true
    @State private var isBatchTagPresented = false
    
    // MARK: - Initialization
    
    /// 创建题库列表视图
    /// - Parameter router: 注入的路由器
    public init(router: LibraryRouter) {
        self.router = router
    }
    
    // MARK: - Body
    
    /// 题库列表界面的视图层次
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                if let vm = viewModel {
                    if vm.errorMessage != nil && vm.filteredItems.isEmpty {
                        // 仅在无缓存数据时展示全屏错误；有缓存时保留已有列表，
                        // 避免刷新失败导致用户已浏览的内容消失
                        ContentUnavailableView {
                            Label(L10n.Errors.loadFailed, systemImage: "exclamationmark.triangle")
                        } description: {
                            Text(L10n.Errors.tryAgainLater)
                        } actions: {
                            Button(L10n.Common.retry) {
                                Task { await vm.loadDataAsync() }
                            }
                        }
                    } else {
                        LibraryListView(
                            selectedItemIDs: $selectedItemIDs,
                            router: router,
                            viewModel: vm
                        )
                    }
                } else {
                    ProgressView()
                }
            }
            .environment(\.editMode, $editMode)
            .searchable(text: Binding(
                get: { viewModel?.searchText ?? "" },
                set: { viewModel?.searchText = $0 }
            ), prompt: L10n.Library.searchPlaceholder)
            .navigationTitle(L10n.Library.title)
            .toolbar {
                // 编辑模式左上角：全选 / 取消全选（Apple 文件 App 模式）
                if editMode.isEditing {
                    ToolbarItem(placement: .topBarLeading) {
                        let allIDs = Set(viewModel?.filteredItems.map(\.id) ?? [])
                        let isAllSelected = !allIDs.isEmpty && selectedItemIDs == allIDs
                        Button(isAllSelected ? L10n.Library.deselectAll : L10n.Library.selectAll) {
                            if isAllSelected {
                                selectedItemIDs.removeAll()
                            } else {
                                selectedItemIDs = allIDs
                            }
                        }
                        .accessibilityValue(L10n.Accessibility.selectAllButton(selected: selectedItemIDs.count, total: allIDs.count))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if editMode.isEditing {
                        Button(L10n.Common.done) {
                            withAnimation {
                                editMode = .inactive
                                selectedItemIDs.removeAll()
                            }
                        }
                        .fontWeight(.bold)
                    } else {
                        HStack(spacing: 12) {
                            // 排序（Apple Reminders 风格 Menu）
                            if let vm = viewModel {
                                Menu {
                                    ForEach(LibrarySortOption.allCases) { option in
                                        Button {
                                            vm.sortOption = option
                                        } label: {
                                            if vm.sortOption == option {
                                                Label(option.displayName, systemImage: "checkmark")
                                            } else {
                                                Text(option.displayName)
                                            }
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.arrow.down")
                                }
                            }

                            // 筛选
                            Button {
                                isFilterPresented = true
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease.circle")
                            }
                        }
                    }
                }
                
                if editMode.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label(L10n.Common.delete, systemImage: "trash")
                        }
                        .disabled(selectedItemIDs.isEmpty)
                        .confirmationDialog(L10n.Library.deleteConfirmTitle, isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button(L10n.Library.selectedCount(selectedItemIDs.count), role: .destructive) {
                                deleteSelectedItems()
                            }
                            Button(L10n.Common.cancel, role: .cancel) { }
                        } message: {
                            Text(L10n.Library.deleteConfirmMessage)
                        }
                        
                        Spacer()

                        // 批量打标签
                        Button {
                            isBatchTagPresented = true
                        } label: {
                            Label(L10n.Library.batchTag, systemImage: "tag")
                        }
                        .disabled(selectedItemIDs.isEmpty)

                        Spacer()

                        Text(L10n.Library.selectedCount(selectedItemIDs.count))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button {
                            isExportSheetPresented = true
                        } label: {
                            Label(L10n.Library.export, systemImage: "square.and.arrow.up")
                        }
                        .disabled(selectedItemIDs.isEmpty)
                    }
                }
            }
            .sheet(isPresented: $isFilterPresented) {
                if let vm = viewModel {
                    LibraryFilterSheet(viewModel: vm)
                }
            }
            .sheet(isPresented: $isExportSheetPresented) {
                ResolvedExportSheet(ids: selectedItemIDs)
            }
            .sheet(isPresented: $isBatchTagPresented) {
                if let vm = viewModel {
                    BatchTagSheet(viewModel: vm, selectedItemIDs: selectedItemIDs)
                }
            }
            .navigationDestination(for: LibraryDestination.self) { destination in
                    switch destination {
                    case .placeholder:
                        Text(L10n.Common.comingSoon)
                    case .detail(let item):
                        LibraryDetailView(router: router, item: item)
                    }
                }
                .alert(viewModel?.operationError ?? "", isPresented: Binding(
                    get: { viewModel?.operationError != nil },
                    set: { if !$0 { viewModel?.operationError = nil } }
                )) {
                    Button(L10n.Common.ok, role: .cancel) {}
                }
                .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
                .onReceive(NotificationCenter.default.publisher(for: .switchToLibraryTab)) { notification in
                    if let userInfo = notification.userInfo,
                       let subject = userInfo["subject"] as? String,
                       let vm = viewModel {
                        vm.resetFilters()
                        vm.selectedSubjects.insert(subject)
                    }
                }
                .task {
                    if isFirstAppear {
                        let vm = LibraryViewModel(repositories: repositories)
                        self.viewModel = vm
                        await vm.loadDataAsync()
                        isFirstAppear = false
                    } else {
                        await viewModel?.loadDataAsync()
                    }
                }
                .onDisappear {
                    viewModel?.cancelTasks()
                }
        }
        .background {
            // 液态渐变背景
            ZStack {
                Color(UIColor.systemGroupedBackground)
                
                GeometryReader { proxy in
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 400, height: 400)
                        .blur(radius: 80)
                        .offset(x: -100, y: 100)
                    
                    Circle()
                        .fill(Color.indigo.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: proxy.size.width - 200, y: proxy.size.height / 2)
                }
                .ignoresSafeArea()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func deleteSelectedItems() {
        guard let vm = viewModel else { return }
        let ids = selectedItemIDs
        Task { await vm.deleteItems(ids: ids) }
        withAnimation {
            selectedItemIDs.removeAll()
        }
    }
}

#Preview {
    LibraryView(router: LibraryRouter())
}
