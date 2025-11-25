//
//  ReviewViewModel.swift
//  NotBad
//
//  复习 ViewModel
//

import SwiftUI
import SwiftData

/// 复习 ViewModel
@MainActor
@Observable
final class ReviewViewModel {
    
    // MARK: - State
    
    var currentIndex = 0
    var showCompletionAlert = false
    var reviewedCount = 0
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Computed
    
    func reviewItems(from allItems: [ReviewItem]) -> [ReviewItem] {
        allItems.sorted { item1, item2 in
            // 按掌握度排序：未掌握优先
            if item1.masteryLevel != item2.masteryLevel {
                return item1.masteryLevel < item2.masteryLevel
            }
            // 同等掌握度按复习次数排序（少的优先）
            return item1.reviewCount < item2.reviewCount
        }
    }
    
    // MARK: - Actions
    
    func handleMasteryUpdate(for item: ReviewItem, level: MasteryLevel) {
        guard let modelContext = modelContext else { return }
        
        // 更新掌握度
        item.mastery = level
        
        // 增加复习次数
        item.reviewCount += 1
        
        // 更新时间
        item.updatedAt = Date()
        
        // 计算下次复习时间
        let interval = ReviewInterval.calculate(reviewCount: item.reviewCount, mastery: level)
        item.nextReviewDate = interval.nextReviewDate
        
        // 保存
        try? modelContext.save()
        
        // 增加已复习计数
        reviewedCount += 1
    }
    
    func moveToNext(totalCount: Int) {
        if currentIndex < totalCount - 1 {
            currentIndex += 1
        } else {
            showCompletionAlert = true
        }
    }
    
    func reset() {
        currentIndex = 0
        reviewedCount = 0
    }
}
