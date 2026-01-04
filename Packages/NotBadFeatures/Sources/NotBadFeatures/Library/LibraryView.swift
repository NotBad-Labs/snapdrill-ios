//
//  LibraryView.swift
//  NotBadFeatureLibrary
//
//  Created by Yiming Liao on 2025/12/29.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  题库列表界面，支持题目浏览和筛选
//

import SwiftUI
import Observation
import NotBadCore
import NotBadUI
import NotBadData
import SwiftData

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
///
/// ## 视图结构
/// - 使用 `NavigationStack` 绑定到注入的 ``LibraryRouter``。
/// - 空状态时显示 `ContentUnavailableView`。
public struct LibraryView: View {
    @Bindable private var router: LibraryRouter
    @State private var searchText = ""
    @State private var isFilterPresented = false
    @State private var selectedSubjects: Set<String> = []
    @State private var selectedTags: Set<String> = []
    
    // Native Selection State
    @State private var selectedItemIDs: Set<ReviewItemModel.ID> = []
    @State private var isExportSheetPresented = false
    @State private var editMode: EditMode = .inactive // Explicit State
    
    @State private var showDeleteConfirmation = false
    
    public init(router: LibraryRouter) {
        self.router = router
    }
    
    @Environment(\.modelContext) private var modelContext
    
    private func deleteSelectedItems() {
        do {
            let descriptor = FetchDescriptor<ReviewItemModel>()
            let allItems = try modelContext.fetch(descriptor)
            let itemsToDelete = allItems.filter { selectedItemIDs.contains($0.id) }
            
            withAnimation {
                for item in itemsToDelete {
                    modelContext.delete(item)
                }
                selectedItemIDs.removeAll()
            }
            
            // Explicitly save to ensure Dashboard stats update immediately
            try? modelContext.save()
        } catch {
            print("Failed to delete items: \(error)")
        }
    }
    
    public var body: some View {
        NavigationStack(path: $router.path) {
            ZStack(alignment: .bottom) {
                LibraryListView(
                    searchText: searchText,
                    selectedSubjects: $selectedSubjects, // Pass Binding
                    selectedTags: selectedTags,
                    selectedItemIDs: $selectedItemIDs,
                    router: router
                )
            }
            .environment(\.editMode, $editMode) // Inject explicit state
            .searchable(text: $searchText, prompt: "搜索题目内容")
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
                LibraryFilterSheet(
                    selectedSubjects: $selectedSubjects,
                    selectedTags: $selectedTags,
                    onReset: {
                        selectedSubjects.removeAll()
                        selectedTags.removeAll()
                    },
                    onApply: { }
                )
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
                       let subject = userInfo["subject"] as? String {
                        selectedSubjects.removeAll()
                        selectedTags.removeAll()
                        searchText = ""
                        selectedSubjects.insert(subject)
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
