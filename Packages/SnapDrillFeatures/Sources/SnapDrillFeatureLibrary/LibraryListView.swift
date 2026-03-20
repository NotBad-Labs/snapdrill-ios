//
//  LibraryListView.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  题库列表视图，展示特定筛选条件下的错题列表。
//

import SwiftUI
import SwiftData
import SnapDrillCore
import SnapDrillData

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    
    // MARK: - Properties
    
    @Binding var selectedItemIDs: Set<UUID>
    
    @Bindable var router: LibraryRouter
    @Bindable var viewModel: LibraryViewModel
    
    @Environment(\.editMode) private var editMode
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
            // Subject Filter Header
            Section {
                 ScrollView(.horizontal, showsIndicators: false) {
                     HStack(spacing: 12) {
                         ForEach(viewModel.subjects) { subject in
                             Button {
                                 if viewModel.selectedSubjects.contains(subject.name) {
                                     viewModel.selectedSubjects.remove(subject.name)
                                 } else {
                                     viewModel.selectedSubjects.insert(subject.name)
                                 }
                             } label: {
                                 SubjectCapsule(subject: subject, isSelected: viewModel.selectedSubjects.contains(subject.name))
                             }
                             .buttonStyle(.plain)
                         }
                     }
                     .padding(.horizontal, 4)
                     .padding(.vertical, 8)
                 }
                 .listRowInsets(EdgeInsets())
                 .listRowBackground(Color.clear)
            }
            
            // 活跃过滤指示器：标签过滤时显示，方便用户感知和快速清除
            if !viewModel.selectedTags.isEmpty {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(viewModel.selectedTags), id: \.self) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                        .font(.caption)
                                    Button {
                                        viewModel.selectedTags.remove(tag)
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.caption2)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                            }
                            Button(L10n.Library.clearFilters) {
                                viewModel.selectedTags.removeAll()
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 4)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
            }

            if viewModel.filteredItems.isEmpty {
                if viewModel.searchText.isEmpty && viewModel.selectedSubjects.isEmpty && viewModel.selectedTags.isEmpty {
                    ContentUnavailableView {
                        Label(L10n.Library.noItems, systemImage: "books.vertical")
                    } description: {
                        Text(L10n.Library.noItemsHint)
                    } actions: {
                        Button(L10n.Dashboard.goCapture) {
                            NotificationCenter.default.post(name: .switchToCaptureTab, object: nil)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            } else {
                ForEach(viewModel.filteredItems) { item in
                    // NavigationLink 提供标准 > 箭头和 VoiceOver 导航语义；
                    // List(selection:) 在 editMode 下自动禁用导航，无需手动 guard
                    NavigationLink(value: LibraryDestination.detail(item)) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(item.content ?? "")
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
                    }
                    // 长按进入多选模式（iOS 标准交互）
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 0.4).onEnded { _ in
                            withAnimation { editMode?.wrappedValue = .active }
                        }
                    )
                    .listRowBackground(Rectangle().fill(.regularMaterial))
                    .listRowSeparator(.hidden)
                    .tag(item.id)
                }
                .onDelete { offsets in
                    // SnapDrill 无回收站，删除不可逆，需确认
                    swipeDeleteIDs = Set(offsets.map { viewModel.filteredItems[$0].id })
                    showSwipeDeleteConfirm = true
                }
                .deleteDisabled(editMode?.wrappedValue.isEditing == true)
                
                // Infinite Scroll Trigger
                if !viewModel.filteredItems.isEmpty {
                    Color.clear
                        .frame(height: 1)
                        .onAppear {
                            Task {
                                await viewModel.loadMore()
                            }
                        }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.clear)
        .listRowSpacing(12)
        .confirmationDialog(L10n.Library.deleteConfirmTitle, isPresented: $showSwipeDeleteConfirm, titleVisibility: .visible) {
            Button(L10n.Common.delete, role: .destructive) {
                Task { await viewModel.deleteItems(ids: swipeDeleteIDs) }
                swipeDeleteIDs.removeAll()
            }
            Button(L10n.Common.cancel, role: .cancel) {
                swipeDeleteIDs.removeAll()
            }
        } message: {
            Text(L10n.Library.deleteConfirmMessage)
        }
    }
}

#Preview {
    let schema = Schema([ReviewItemModel.self, SubjectModel.self, SourceModel.self, TagModel.self, GradeModel.self])
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
