//
//  LibraryView.swift
//  NotBad
//
//  错题库视图 - 展示所有错题列表
//

import SwiftUI
import SwiftData
import ReviewKit

struct LibraryView: View {
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var items: [ReviewItemModel]
    
    @State private var searchText = ""
    @State private var selectedSubject: Subject?
    
    private var filteredItems: [ReviewItemModel] {
        var result = items
        
        // 按学科筛选
        if let subject = selectedSubject {
            result = result.filter { $0.subject == subject }
        }
        
        // 按关键词搜索
        if !searchText.isEmpty {
            result = result.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.note.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("题库")
            .searchable(text: $searchText, prompt: "搜索错题")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("全部") { selectedSubject = nil }
                        ForEach(Subject.allCases) { subject in
                            Button(subject.displayName) {
                                selectedSubject = subject
                            }
                        }
                    } label: {
                        Label("筛选", systemImage: "line.3.horizontal.decrease.circle")
                    }
                }
            }
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "还没有错题",
            systemImage: "tray",
            description: Text("点击「录入」添加第一道错题")
        )
    }
    
    private var listView: some View {
        List {
            ForEach(filteredItems) { item in
                ItemRow(item: item)
            }
        }
        .listStyle(.plain)
        .overlay {
            if filteredItems.isEmpty && !searchText.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
