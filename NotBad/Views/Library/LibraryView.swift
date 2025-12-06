//
//  LibraryView.swift
//  NotBad
//
//  题库列表视图
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \ReviewItemModel.createdAt, order: .reverse)
    private var items: [ReviewItemModel]
    
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                if items.isEmpty {
                    ContentUnavailableView(
                        "还没有错题",
                        systemImage: "tray",
                        description: Text("点击录入添加第一道错题")
                    )
                } else {
                    ForEach(items) { item in
                        ItemRow(item: item)
                    }
                    .onDelete(perform: deleteItems)
                }
            }
            .navigationTitle("题库")
            .toolbar {
                EditButton()
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        for index in offsets {
            let item = items[index]
            // 删除关联的图片文件
            ImageStorageService.shared.delete(fileName: item.imagePath)
            modelContext.delete(item)
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
