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
    
    // Native Selection State
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var isExportSheetPresented = false
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteConfirmation = false
    @State private var isFilterPresented = false
    @State private var isFirstAppear = true
    
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
                    LibraryListView(
                        selectedItemIDs: $selectedItemIDs,
                        router: router,
                        viewModel: vm
                    )
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
            .navigationDestination(for: LibraryDestination.self) { destination in
                    switch destination {
                    case .placeholder:
                        Text(L10n.Common.comingSoon)
                    case .detail(let item):
                        LibraryDetailView(router: router, item: item)
                    }
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
            // Liquid Mesh Gradient
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
