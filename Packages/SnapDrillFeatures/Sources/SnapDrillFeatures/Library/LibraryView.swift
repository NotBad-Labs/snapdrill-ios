//
//  LibraryView.swift
//  SnapDrillFeatureLibrary
//
//  Created by SnapDrill Labs on 2025/12/29.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  题库列表界面，支持题目浏览和筛选
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// 题库列表界面
///
/// 展示用户保存的所有题目列表，提供主要的浏览和管理功能。
///
/// ## 数据源
/// 使用 SwiftData 查询（`@Query`）从数据库实时获取 `ReviewItemModel` 列表，
/// 并按创建时间倒序排列（最新的在最前）。
///
/// ## 交互
/// - **列表点击**: 跳转到 ``LibraryDetailView`` 查看详情。
/// - **滑动删除**: 允许用户快速从数据库中移除题目。
/// ## 视图结构
/// - 使用 `NavigationStack` 绑定到注入的 ``LibraryRouter``。
/// - 空状态时显示 `ContentUnavailableView`。
public struct LibraryView: View {
    @Bindable private var router: LibraryRouter
    @Environment(\.repositories) private var repos
    
    @State private var viewModel: LibraryViewModel?
    
    // Native Selection State
    @State private var selectedItemIDs: Set<UUID> = []
    @State private var isExportSheetPresented = false
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteConfirmation = false
    @State private var isFilterPresented = false
    @State private var isFirstAppear = true
    
    public init(router: LibraryRouter) {
        self.router = router
    }
    
    private func deleteSelectedItems() {
        viewModel?.deleteItems(ids: selectedItemIDs)
        withAnimation {
            selectedItemIDs.removeAll()
        }
    }
    
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
            .searchable(text: Bindable(viewModel ?? LibraryViewModel(reviewRepo: repos.review, subjectRepo: repos.subject, tagRepo: repos.tag)).searchText, prompt: "搜索题目内容")
            .navigationTitle("题库")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if editMode.isEditing {
                            Button("完成") {
                                withAnimation {
                                    editMode = .inactive
                                    selectedItemIDs.removeAll()
                                }
                            }
                            .fontWeight(.bold)
                        } else {
                            Menu {
                                Button {
                                    withAnimation {
                                        editMode = .active
                                    }
                                } label: {
                                    Label("选择题目", systemImage: "checkmark.circle")
                                }
                                
                                Button {
                                    isFilterPresented = true
                                } label: {
                                    Label("筛选与排序", systemImage: "line.3.horizontal.decrease.circle")
                                }
                            } label: {
                                Label("管理", systemImage: "ellipsis.circle")
                            }
                        }
                    }
                }
                
                if editMode.isEditing {
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("删除", systemImage: "trash")
                        }
                        .disabled(selectedItemIDs.isEmpty)
                        .confirmationDialog("确认删除", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                            Button("删除 \(selectedItemIDs.count) 个项目", role: .destructive) {
                                deleteSelectedItems()
                            }
                            Button("取消", role: .cancel) { }
                        } message: {
                            Text("此操作无法撤销。")
                        }
                        
                        Spacer()
                        
                        Text("已选 \(selectedItemIDs.count) 项")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Button {
                            isExportSheetPresented = true
                        } label: {
                            Label("导出/分享", systemImage: "square.and.arrow.up")
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
                        Text("即将上线")
                    case .detail(let item):
                        LibraryDetailView(router: router, item: item)
                    }
                }
                .toolbar(editMode.isEditing ? .hidden : .visible, for: .tabBar)
                .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("SwitchToLibraryTab"))) { notification in
                    if let userInfo = notification.userInfo,
                       let subject = userInfo["subject"] as? String,
                       let vm = viewModel {
                        vm.resetFilters()
                        vm.selectedSubjects.insert(subject)
                    }
                }
                .task {
                    if isFirstAppear {
                        let vm = LibraryViewModel(
                            reviewRepo: repos.review,
                            subjectRepo: repos.subject,
                            tagRepo: repos.tag
                        )
                        self.viewModel = vm
                        await vm.loadDataAsync()
                        isFirstAppear = false
                    } else {
                        await viewModel?.loadDataAsync()
                    }
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
}

#Preview {
    LibraryView(router: LibraryRouter())
        .modelContainer(for: [SubjectModel.self, ReviewItemModel.self], inMemory: true)
}
