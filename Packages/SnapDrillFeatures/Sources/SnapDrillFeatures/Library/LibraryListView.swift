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
import SnapDrillDomain
import SnapDrillCore
import SnapDrillData

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    
    // MARK: - Properties
    
    @Binding var selectedItemIDs: Set<UUID>
    
    @Bindable var router: LibraryRouter
    @Bindable var viewModel: LibraryViewModel
    
    @Environment(\.editMode) private var editMode
    
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
                             SubjectCapsule(subject: subject, isSelected: viewModel.selectedSubjects.contains(subject.name))
                                 .onTapGesture {
                                     if viewModel.selectedSubjects.contains(subject.name) {
                                         viewModel.selectedSubjects.remove(subject.name)
                                     } else {
                                         viewModel.selectedSubjects.insert(subject.name)
                                     }
                                 }
                         }
                     }
                     .padding(.horizontal, 4)
                     .padding(.vertical, 8)
                 }
                 .listRowInsets(EdgeInsets())
                 .listRowBackground(Color.clear)
            }
            
            if viewModel.filteredItems.isEmpty {
                if viewModel.searchText.isEmpty && viewModel.selectedSubjects.isEmpty && viewModel.selectedTags.isEmpty {
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
                    ContentUnavailableView.search(text: viewModel.searchText)
                }
            } else {
                ForEach(viewModel.filteredItems) { item in
                    Button(action: {
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
                    .buttonStyle(.plain)
                    .listRowBackground(Rectangle().fill(.regularMaterial))
                    .listRowSeparator(.hidden)
                    .tag(item.id)
                }
                .onDelete { offsets in
                    let idsToDelete = Set(offsets.map { viewModel.filteredItems[$0].id })
                    viewModel.deleteItems(ids: idsToDelete)
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
    }
}

#Preview {
    let repos = PreviewRepositoryContainer()
    let useCases = DefaultUseCaseContainer(repositories: repos)
    LibraryListView(
        selectedItemIDs: .constant([]),
        router: LibraryRouter(),
        viewModel: LibraryViewModel(
            reviewUseCase: useCases.review,
            taxonomyUseCase: useCases.taxonomy
        )
    )
}
