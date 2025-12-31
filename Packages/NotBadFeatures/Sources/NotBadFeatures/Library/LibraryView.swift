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
            .searchable(text: $searchText, prompt: "搜索题目内容")
            .navigationTitle("题库")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack {
                        if editMode.isEditing == false {
                            Button(action: { isFilterPresented = true }, label: {
                                Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                                    .symbolVariant(!selectedSubjects.isEmpty || !selectedTags.isEmpty ? .fill : .none)
                            })
                        }
                        
                        Button(editMode.isEditing ? "完成" : "选择") {
                            withAnimation {
                                editMode = editMode.isEditing ? .inactive : .active
                                if !editMode.isEditing {
                                    selectedItemIDs.removeAll()
                                }
                            }
                        }
                        .fontWeight(editMode.isEditing ? .bold : .regular)
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
                // We need to resolve IDs to Models. passing the IDs to the sheet or resolving here?
                // For simplicity, let's pass a closure or resolve it in the sheet if we can,
                // But better to resolve here to pass [ReviewItemModel]
                // Note: Query is inside subview. We need access to modelContext here to fetch.
                // Or we update ExportOptionsSheet to take IDs?
                // Let's resolve efficiently in a computed property wrapper or fetch.
                // Since we don't have the `items` array here (it's in subview), we might need to fetch by IDs.
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

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    var searchText: String
    @Binding var selectedSubjects: Set<String> // Changed to Binding
    var selectedTags: Set<String>
    
    @Binding var selectedItemIDs: Set<ReviewItemModel.ID>
    
    @Bindable var router: LibraryRouter
    
    @Query private var items: [ReviewItemModel]
    @Query(sort: \SubjectModel.sortOrder) private var subjects: [SubjectModel] // Added Query
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    init(
        searchText: String,
        selectedSubjects: Binding<Set<String>>, // Changed to Binding
        selectedTags: Set<String>,
        selectedItemIDs: Binding<Set<ReviewItemModel.ID>>,
        router: LibraryRouter
    ) {
        self.searchText = searchText
        self._selectedSubjects = selectedSubjects // Assign Binding
        self.selectedTags = selectedTags
        self._selectedItemIDs = selectedItemIDs
        self.router = router
        
        if searchText.isEmpty && selectedSubjects.wrappedValue.isEmpty && selectedTags.isEmpty {
             _items = Query(sort: \ReviewItemModel.createdAt, order: .reverse)
        } else {
            // Predicate issue: accessing wrappedValue might not be stable in macro?
            // Actually, we can't access Binding values in Predicate easily.
            // We should use the local value passed in, or rely on filtering in memory if predicate is too hard.
            // But wait, the init logic is creating the Query.
            // Predicate construction cannot capture Binding.
            // We can capture the initial value.
            // However, Query update relies on the View update.
            // Let's stick to the existing patterns.
            // Wait, previous code used `selectedSubjects` which was a let.
            // Now it is a Binding. Accessing `selectedSubjects.wrappedValue` here works for INIT,
            // but for updates, SwiftUI re-inits the view body, not necessarily the struct query.
            // Standard SwiftUI Query: The predicate is constant unless defined as a property that resets the query?
            // Actually `init` is called on view update. So constructing Query in init works if data changes.
            let subjects = selectedSubjects.wrappedValue
             _items = Query(
                filter: #Predicate<ReviewItemModel> { item in
                    (searchText.isEmpty || item.content.contains(searchText))
                    // Note: Predicate support for Sets is limited.
                    // Previous code relied on `filteredItems` computed property for advanced filtering.
                    // The Query above ONLY filtered by text.
                    // So we are safe.
                },
                sort: \ReviewItemModel.createdAt,
                order: .reverse
            )
        }
    }
    
    // In-Memory Filter
    var filteredItems: [ReviewItemModel] {
        items.filter { item in
            if !selectedSubjects.isEmpty {
                if !selectedSubjects.contains(item.subject) { return false }
            }
            if !selectedTags.isEmpty {
                guard let itemTags = item.tags else { return false }
                let itemTagNames = Set(itemTags.map { $0.name })
                if itemTagNames.isDisjoint(with: selectedTags) { return false }
            }
            return true
        }
    }
    
    var body: some View {
        List(selection: $selectedItemIDs) {
            // Subject Filter Header
            Section {
                 ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 12) {
                         ForEach(subjects) { subject in
                             SubjectCapsule(subject: subject, isSelected: selectedSubjects.contains(subject.name))
                                 .onTapGesture {
                                     if selectedSubjects.contains(subject.name) {
                                         selectedSubjects.remove(subject.name)
                                     } else {
                                         // Single select or Multi? Set supports multi.
                                         // Let's allow multi select or toggle.
                                         // If we want "Browse by Subject" usually means switch.
                                         // But filter suggests multi. Let's do toggle.
                                          if selectedSubjects.contains(subject.name) {
                                             selectedSubjects.remove(subject.name)
                                          } else {
                                              selectedSubjects.insert(subject.name)
                                          }
                                     }
                                 }
                         }
                     }
                     .padding(.horizontal, 4)
                     .padding(.vertical, 8)
                 }
                 .listRowInsets(EdgeInsets()) // Edge to edge
                 .listRowBackground(Color.clear)
            }
            
            if filteredItems.isEmpty {
                if searchText.isEmpty && selectedSubjects.isEmpty && selectedTags.isEmpty {
                    ContentUnavailableView {
                        Label("暂无错题", systemImage: "books.vertical")
                    } description: {
                        Text("去拍摄你的第一道错题吧")
                    } actions: {
                        Button("去采集") {
                            NotificationCenter.default.post(name: NSNotification.Name("SwitchToCaptureTab"), object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: searchText)
                }
            } else {
                ForEach(filteredItems) { item in
                    Button(action: {
                        // In Edit Mode, selection is handled by List.
                        // In Normal Mode, navigate.
                        if editMode?.wrappedValue.isEditing == false {
                            router.push(.detail(item))
                        }
                    }, label: {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.content)
                                .font(.headline)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            HStack(spacing: 8) {
                                Text(item.subject)
                                    .font(.caption2.bold())
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundStyle(.blue)
                                    .clipShape(Capsule())
                                
                                Text(item.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    })
                    .buttonStyle(.plain) // Standard list row style
                    .listRowBackground(Rectangle().fill(.regularMaterial)) // Glass Cells
                    .listRowSeparator(.hidden)
                    .tag(item.id) // Critical for Selection
                }
                .onDelete(perform: deleteItems)
                .deleteDisabled(editMode?.wrappedValue.isEditing == true)
            }
        }
        .scrollContentBackground(.hidden) // Key for Glass Effect
        .background(Color.clear)
        .listRowSpacing(12) // iOS 26 airy layout
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets where index < filteredItems.count {
                modelContext.delete(filteredItems[index])
            }
        }
    }
}

struct SubjectCapsule: View {
    let subject: SubjectModel
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: subject.icon)
            Text(subject.name)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(isSelected ? Color(hex: subject.colorHex) : Color(hex: subject.colorHex).opacity(0.1))
        .foregroundStyle(isSelected ? .white : Color(hex: subject.colorHex))
        .clipShape(Capsule())
        .animation(.spring, value: isSelected)
    }
}
