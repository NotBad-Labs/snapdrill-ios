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
    @State private var viewModel = LibraryViewModel()
    
    private var filteredItems: [ReviewItem] {
        viewModel.filteredItems(from: items)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                
                if filteredItems.isEmpty {
                    ContentUnavailableView(
                        "暂无错题",
                        systemImage: "books.vertical",
                        description: Text("快去录入你的第一道错题吧")
                    )
                } else {
                    itemList
                }
            }
            .navigationTitle("题库")
            .searchable(text: $viewModel.searchText, prompt: "搜索标题或知识点")
            .onAppear {
                viewModel.configure(with: modelContext)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                FilterChip(
                    title: "全部",
                    isSelected: viewModel.selectedSubject == nil,
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.selectSubject(nil)
                        }
                    }
                )
                
                ForEach(Subject.allCases, id: \.self) { subject in
                    FilterChip(
                        title: subject.displayName,
                        isSelected: viewModel.selectedSubject == subject,
                        action: {
                            withAnimation(.spring(response: 0.3)) {
                                viewModel.selectSubject(subject)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(uiColor: .systemBackground))
    }
    
    private var itemList: some View {
        List {
            ForEach(filteredItems) { item in
                NavigationLink(value: item) {
                    ItemRow(item: item)
                }
            }
            .onDelete { offsets in
                withAnimation {
                    viewModel.deleteItems(from: filteredItems, at: offsets)
                }
            }
        }
        .listStyle(.plain)
        .navigationDestination(for: ReviewItem.self) { item in
            ItemDetailView(item: item)
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
                    Text(item.subject.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(item.subject.color.opacity(0.1))
                        .foregroundStyle(item.subject.color)
                        .clipShape(Capsule())
                    
                    // 掌握度
                    MasteryBadge(level: item.mastery)
                    
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
}

#Preview {
    LibraryView()
        .modelContainer(for: ReviewItem.self, inMemory: true)
}
