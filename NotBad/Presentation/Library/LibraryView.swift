//
//  LibraryView.swift
//  NotBad
//
//  题库视图 - iOS 26 现代化设计
//

import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(sort: \ReviewItem.createdAt, order: .reverse) private var items: [ReviewItem]
    @Environment(\.modelContext) private var modelContext
    
    @State private var searchText = ""
    @State private var selectedSubject: String?
    
    let subjects = ["全部", "语文", "数学", "英语", "物理", "化学", "生物", "历史", "地理", "政治"]
    
    var filteredItems: [ReviewItem] {
        items.filter { item in
            let matchesSearch = searchText.isEmpty || 
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.tags.localizedCaseInsensitiveContains(searchText)
            
            let matchesSubject = selectedSubject == nil || selectedSubject == "全部" || item.subject == selectedSubject
            
            return matchesSearch && matchesSubject
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 筛选栏
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(subjects, id: \.self) { subject in
                            FilterChip(
                                title: subject,
                                isSelected: (selectedSubject ?? "全部") == subject,
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedSubject = subject
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(uiColor: .systemBackground))
                
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "暂无错题",
                        systemImage: "books.vertical",
                        description: Text("快去录入你的第一道错题吧")
                    )
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            NavigationLink(value: item) {
                                ItemRow(item: item)
                            }
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(.plain)
                    .navigationDestination(for: ReviewItem.self) { item in
                        ItemDetailView(item: item)
                    }
                }
            }
            .navigationTitle("题库")
            .searchable(text: $searchText, prompt: "搜索标题或标签")
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
            try? modelContext.save()
        }
    }
}

// MARK: - 筛选芯片

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    isSelected ? 
                    LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .leading, endPoint: .trailing) :
                    LinearGradient(colors: [Color(uiColor: .secondarySystemBackground)], startPoint: .leading, endPoint: .trailing)
                )
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
                .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, y: 2)
        }
    }
}

// MARK: - 列表行

struct ItemRow: View {
    let item: ReviewItem
    
    var body: some View {
        HStack(spacing: 12) {
            // 缩略图
            if let data = item.imageData, let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 70, height: 70)
                    .overlay {
                        Image(systemName: "photo")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
            }
            
            // 信息
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.headline)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    // 学科标签
                    Text(item.subject)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                    
                    // 掌握度
                    HStack(spacing: 3) {
                        Image(systemName: masteryIcon)
                            .font(.caption2)
                        Text(masteryText)
                            .font(.caption)
                    }
                    .foregroundStyle(masteryColor)
                    
                    Spacer()
                    
                    // 日期
                    Text(item.createdAt, format: .dateTime.month().day())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private var masteryIcon: String {
        switch item.masteryLevel {
        case 3: return "checkmark.seal.fill"
        case 2: return "checkmark.circle.fill"
        case 1: return "questionmark.circle.fill"
        default: return "xmark.circle.fill"
        }
    }
    
    private var masteryText: String {
        switch item.masteryLevel {
        case 3: return "掌握"
        case 2: return "熟悉"
        case 1: return "模糊"
        default: return "不会"
        }
    }
    
    private var masteryColor: Color {
        switch item.masteryLevel {
        case 3: return .green
        case 2: return .mint
        case 1: return .orange
        default: return .red
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
