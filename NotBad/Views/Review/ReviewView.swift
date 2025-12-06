//
//  ReviewView.swift
//  NotBad
//
//  复习视图
//

import SwiftUI
import SwiftData

struct ReviewView: View {
    @Query(sort: \ReviewItemModel.nextReviewDate)
    private var allItems: [ReviewItemModel]
    
    private var dueItems: [ReviewItemModel] {
        allItems.filter { $0.needsReview }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if dueItems.isEmpty {
                    emptyStateView
                } else {
                    reviewListView
                }
            }
            .navigationTitle("复习")
        }
    }
    
    // MARK: - Subviews
    
    private var emptyStateView: some View {
        ContentUnavailableView(
            "暂无待复习",
            systemImage: "checkmark.circle",
            description: Text("所有错题都已复习完成")
        )
    }
    
    private var reviewListView: some View {
        List(dueItems) { item in
            ItemRow(item: item)
        }
    }
}

#Preview {
    ReviewView()
        .modelContainer(for: ReviewItemModel.self, inMemory: true)
}
