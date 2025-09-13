//
//  QuestionBankTabView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//  题库功能模块 - 错题管理和分类
//

import SwiftUI
import SwiftData

/// 题库Tab视图 - 错题管理和分类功能
struct QuestionBankTabView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var reviewItems: [ReviewItem]
    @State private var searchText = ""
    @State private var selectedSubject = "全部"
    @State private var selectedMasteryLevel = MasteryLevel.notMastered
    
    private let subjects = ["全部", "数学", "语文", "英语", "物理", "化学", "生物", "历史", "地理", "政治"]
    
    var filteredItems: [ReviewItem] {
        var items = reviewItems
        
        // 按科目筛选
        if selectedSubject != "全部" {
            items = items.filter { $0.content.subject == selectedSubject }
        }
        
        // 按掌握度筛选
        items = items.filter { $0.masteryLevel == selectedMasteryLevel }
        
        // 按搜索文本筛选
        if !searchText.isEmpty {
            items = items.filter { item in
                item.content.recognizedText.localizedCaseInsensitiveContains(searchText) ||
                item.content.subject.localizedCaseInsensitiveContains(searchText) ||
                item.content.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // 按创建时间倒序排列
        return items.sorted { $0.createdAt > $1.createdAt }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 搜索栏
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // 筛选器
                FilterBar(
                    selectedSubject: $selectedSubject,
                    selectedMasteryLevel: $selectedMasteryLevel,
                    subjects: subjects
                )
                .padding(.horizontal)
                
                // 统计信息
                StatsBar(totalItems: reviewItems.count, filteredItems: filteredItems.count)
                    .padding(.horizontal)
                
                // 复习项列表
                if filteredItems.isEmpty {
                    EmptyStateView()
                } else {
                    List {
                        ForEach(filteredItems) { item in
                            ReviewItemRowView(item: item)
                        }
                        .onDelete(perform: deleteItems)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("题库")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }
    
    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }
        }
    }
}

// MARK: - 搜索栏组件
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField("搜索题目、科目或标签...", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 筛选栏组件
struct FilterBar: View {
    @Binding var selectedSubject: String
    @Binding var selectedMasteryLevel: MasteryLevel
    let subjects: [String]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // 科目筛选
                Menu {
                    ForEach(subjects, id: \.self) { subject in
                        Button(subject) {
                            selectedSubject = subject
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedSubject)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                }
                
                // 掌握度筛选
                Menu {
                    ForEach(MasteryLevel.allCases, id: \.self) { level in
                        Button(level.displayName) {
                            selectedMasteryLevel = level
                        }
                    }
                } label: {
                    HStack {
                        Text(selectedMasteryLevel.displayName)
                        Image(systemName: "chevron.down")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - 统计栏组件
struct StatsBar: View {
    let totalItems: Int
    let filteredItems: Int
    
    var body: some View {
        HStack {
            Text("总计: \(totalItems)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if totalItems != filteredItems {
                Text("筛选: \(filteredItems)")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
}

// MARK: - 空状态视图
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("暂无复习项")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Text("去录入页面添加一些题目吧！")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 复习项行视图
struct ReviewItemRowView: View {
    let item: ReviewItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 题目预览
            Text(item.content.recognizedText)
                .font(.body)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            HStack {
                // 科目标签
                Text(item.content.subject)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(6)
                
                // 掌握度标签
                Text(item.masteryLevel.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(masteryLevelColor.opacity(0.1))
                    .foregroundColor(masteryLevelColor)
                    .cornerRadius(6)
                
                Spacer()
                
                // 创建时间
                Text(item.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var masteryLevelColor: Color {
        switch item.masteryLevel {
        case .notMastered:
            return .red
        case .unclear:
            return .orange
        case .mastered:
            return .green
        }
    }
}

#Preview {
    let schema = Schema([
        ReviewItem.self,
        ReviewContent.self,
        ReviewItemMetadata.self,
        StudyRecord.self
    ])
    
    let modelConfiguration = ModelConfiguration(
        schema: schema,
        isStoredInMemoryOnly: true
    )
    
    do {
        let modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        let sampleItem = ReviewItem(
            content: ReviewContent(
                imageData: nil,
                recognizedText: "这是一道数学题：求解方程 x² + 5x + 6 = 0",
                userNotes: "使用因式分解法",
                subject: "数学",
                tags: ["代数", "方程"],
                difficulty: .medium
            ),
            metadata: ReviewItemMetadata(
                ownerId: UUID(),
                parentShareStatus: .none,
                parentAccessRevokedAt: nil,
                sharedWithClassIds: [],
                isArchived: false
            )
        )
        
        modelContainer.mainContext.insert(sampleItem)
        
        return QuestionBankTabView()
            .modelContainer(modelContainer)
    } catch {
        return Text("Preview error: \(error.localizedDescription)")
    }
}
