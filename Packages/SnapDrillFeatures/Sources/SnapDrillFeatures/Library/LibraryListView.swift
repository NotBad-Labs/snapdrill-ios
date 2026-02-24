//
//  LibraryListView.swift
//  SnapDrillFeatureLibrary
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  题库列表视图，展示特定筛选条件下的错题列表。
//

import SwiftUI
import SwiftData
import SnapDrillCore
import SnapDrillUI
import SnapDrillData

/// A subview to handle the dynamic query based on searchText
struct LibraryListView: View {
    var searchText: String
    @Binding var selectedSubjects: Set<String>
    var selectedTags: Set<String>
    
    @Binding var selectedItemIDs: Set<ReviewItemModel.ID>
    
    @Bindable var router: LibraryRouter
    
    @Query private var items: [ReviewItemModel]
    @Query(sort: \SubjectModel.sortOrder) private var subjects: [SubjectModel]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.editMode) private var editMode
    
    init(
        searchText: String,
        selectedSubjects: Binding<Set<String>>,
        selectedTags: Set<String>,
        selectedItemIDs: Binding<Set<ReviewItemModel.ID>>,
        router: LibraryRouter
    ) {
        self.searchText = searchText
        self._selectedSubjects = selectedSubjects
        self.selectedTags = selectedTags
        self._selectedItemIDs = selectedItemIDs
        self.router = router
        
        // Use local variable for logic
        let subjectsFilter = selectedSubjects.wrappedValue
        
        // WrappedValue access in init is valid for struct initialization
        if searchText.isEmpty && subjectsFilter.isEmpty && selectedTags.isEmpty {
             _items = Query(sort: \ReviewItemModel.createdAt, order: .reverse)
        } else {
             _items = Query(
                filter: #Predicate<ReviewItemModel> { item in
                    (searchText.isEmpty || item.content.contains(searchText))
                },
                sort: \ReviewItemModel.createdAt,
                order: .reverse
            )
        }
    }
    
    // In-Memory Filter for complex logic (Sets)
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

#Preview {
    LibraryListView(
        searchText: "",
        selectedSubjects: .constant([]),
        selectedTags: [],
        selectedItemIDs: .constant([]),
        router: LibraryRouter()
    )
    .modelContainer(for: [SubjectModel.self, ReviewItemModel.self], inMemory: true)
}
