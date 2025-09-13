//
//  ReviewItemListView.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import SwiftUI
import SwiftData

struct ReviewItemListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var reviewItems: [ReviewItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingCreateSheet = false
    
    // 依赖注入
    @State private var repository: (any ReviewItemRepository)?
    @State private var getItemsUseCase: (any GetReviewItemsUseCase)?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if reviewItems.isEmpty {
                    EmptyStateView {
                        showingCreateSheet = true
                    }
                } else {
                    List(reviewItems, id: \.id) { item in
                        ReviewItemRowView(item: item)
                    }
                    .refreshable {
                        await loadReviewItems()
                    }
                }
            }
            .navigationTitle("复习项")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateReviewItemView(onCreated: { _ in
                    Task {
                        await loadReviewItems()
                    }
                })
            }
            .task {
                await setupDependencies()
                await loadReviewItems()
            }
            .alert("错误", isPresented: .constant(errorMessage != nil)) {
                Button("确定") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupDependencies() async {
        repository = SwiftDataReviewItemRepository(modelContext: modelContext)
        // TODO: 创建具体的UseCase实现
    }
    
    private func loadReviewItems() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let repository = repository {
                let items = try await repository.getAll()
                await MainActor.run {
                    self.reviewItems = items
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
        
        await MainActor.run {
            isLoading = false
        }
    }
}

// MARK: - Supporting Views

struct ReviewItemRowView: View {
    let item: ReviewItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(item.content.title)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                MasteryLevelBadge(level: item.masteryLevel)
            }
            
            Text(item.content.question)
                .font(.body)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Text(item.content.subject)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .foregroundColor(.blue)
                    .cornerRadius(8)
                
                Text(item.content.difficulty.displayName)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
                
                Spacer()
                
                Text(item.metadata.createdAt, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct MasteryLevelBadge: View {
    let level: MasteryLevel
    
    var body: some View {
        Text(level.displayName)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch level {
        case .notMastered:
            return .red
        case .unclear:
            return .orange
        case .mastered:
            return .green
        }
    }
}

struct EmptyStateView: View {
    let onCreateTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("还没有复习项")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("点击右上角的"+"按钮\n创建你的第一个复习项")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("立即创建") {
                onCreateTapped()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    NavigationView {
        ReviewItemListView()
    }
    .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
