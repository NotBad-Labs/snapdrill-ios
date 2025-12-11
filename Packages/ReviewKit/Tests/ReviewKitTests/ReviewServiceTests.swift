//
//  ReviewServiceTests.swift
//  ReviewKitTests
//
//  ReviewService 单元测试
//

import Testing
import Foundation
@testable import ReviewKit

@Suite("ReviewService Tests")
@MainActor
struct ReviewServiceTests {
    
    let service = ReviewService()
    
    // MARK: - Record Review Tests
    
    @Test("Record review updates mastery level")
    func testRecordReviewUpdatesMasteryLevel() {
        let item = createTestItem()
        
        service.recordReview(for: item, performance: ReviewPerformance.basic)
        
        #expect(item.masteryLevel == ReviewPerformance.basic.rawValue)
    }
    
    @Test("Record review increments review count")
    func testRecordReviewIncrementsReviewCount() {
        let item = createTestItem()
        let initialCount = item.reviewCount
        
        service.recordReview(for: item, performance: ReviewPerformance.basic)
        
        #expect(item.reviewCount == initialCount + 1)
    }
    
    @Test("Record review updates next review date")
    func testRecordReviewUpdatesNextReviewDate() {
        let item = createTestItem()
        let previousDate = item.nextReviewDate
        
        service.recordReview(for: item, performance: ReviewPerformance.easy)
        
        #expect(item.nextReviewDate > previousDate)
    }
    
    @Test("Record review with raw value clamps to valid range")
    func testRecordReviewClampsPerformance() {
        let item = createTestItem()
        
        service.recordReview(for: item, performance: 100)
        
        #expect(item.masteryLevel == 4) // Clamped to max
    }
    
    @Test("Record review with negative value clamps to zero")
    func testRecordReviewClampsNegativePerformance() {
        let item = createTestItem()
        
        service.recordReview(for: item, performance: -10)
        
        #expect(item.masteryLevel == 0) // Clamped to min
    }
    
    @Test("Multiple reviews accumulate correctly")
    func testMultipleReviewsAccumulate() {
        let item = createTestItem()
        
        service.recordReview(for: item, performance: ReviewPerformance.forgot)
        service.recordReview(for: item, performance: ReviewPerformance.vague)
        service.recordReview(for: item, performance: ReviewPerformance.basic)
        
        #expect(item.reviewCount == 3)
    }
    
    // MARK: - Reset Progress Tests
    
    @Test("Reset progress clears mastery and count")
    func testResetProgressClearsState() {
        let item = createTestItem()
        item.masteryLevel = 3
        item.reviewCount = 10
        
        service.resetProgress(for: item)
        
        #expect(item.masteryLevel == 0)
        #expect(item.reviewCount == 0)
    }
    
    @Test("Reset progress sets next review to today")
    func testResetProgressSetsNextReviewToToday() {
        let item = createTestItem()
        item.nextReviewDate = Date.distantFuture
        
        service.resetProgress(for: item)
        
        let now = Date()
        #expect(abs(item.nextReviewDate.timeIntervalSince(now)) < 1)
    }
    
    @Test("Batch reset progress")
    func testBatchResetProgress() {
        let items = [createTestItem(), createTestItem(), createTestItem()]
        for item in items {
            item.masteryLevel = 3
            item.reviewCount = 5
        }
        
        service.resetProgress(for: items)
        
        for item in items {
            #expect(item.masteryLevel == 0)
            #expect(item.reviewCount == 0)
        }
    }
    
    // MARK: - Batch Operations Tests
    
    @Test("Mark items as mastered")
    func testMarkAsMastered() {
        let items = [createTestItem(), createTestItem()]
        
        service.markAsMastered(items: items)
        
        for item in items {
            #expect(item.masteryLevel == MasteryLevel.mastered.rawValue)
        }
    }
    
    @Test("Mark items for review sets next review to now")
    func testMarkForReview() {
        let items = [createTestItem(), createTestItem()]
        for item in items {
            item.nextReviewDate = Date.distantFuture
        }
        
        service.markForReview(items: items)
        
        let now = Date()
        for item in items {
            #expect(abs(item.nextReviewDate.timeIntervalSince(now)) < 1)
        }
    }
    
    // MARK: - Query Helper Tests
    
    @Test("Items due today filter works")
    func testItemsDueToday() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let itemDueToday = createTestItem()
        itemDueToday.nextReviewDate = today.addingTimeInterval(3600) // Today + 1 hour
        
        let itemDueTomorrow = createTestItem()
        itemDueTomorrow.nextReviewDate = tomorrow.addingTimeInterval(3600)
        
        let result = service.itemsDueToday(from: [itemDueToday, itemDueTomorrow])
        
        #expect(result.count == 1)
        #expect(result.first?.id == itemDueToday.id)
    }
    
    @Test("Overdue items filter works")
    func testOverdueItems() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let overdueItem = createTestItem()
        overdueItem.nextReviewDate = yesterday
        
        let futureItem = createTestItem()
        futureItem.nextReviewDate = tomorrow
        
        let result = service.overdueItems(from: [overdueItem, futureItem])
        
        #expect(result.count == 1)
        #expect(result.first?.id == overdueItem.id)
    }
    
    @Test("Mastered items filter works")
    func testMasteredItems() {
        let masteredItem = createTestItem()
        masteredItem.masteryLevel = MasteryLevel.mastered.rawValue
        
        let vagueItem = createTestItem()
        vagueItem.masteryLevel = MasteryLevel.vague.rawValue
        
        let result = service.masteredItems(from: [masteredItem, vagueItem])
        
        #expect(result.count == 1)
        #expect(result.first?.id == masteredItem.id)
    }
    
    // MARK: - Statistics Tests
    
    @Test("Mastery rate calculation")
    func testMasteryRate() {
        let mastered1 = createTestItem()
        mastered1.masteryLevel = MasteryLevel.mastered.rawValue
        
        let mastered2 = createTestItem()
        mastered2.masteryLevel = MasteryLevel.mastered.rawValue
        
        let vague = createTestItem()
        vague.masteryLevel = MasteryLevel.vague.rawValue
        
        let none = createTestItem()
        none.masteryLevel = MasteryLevel.none.rawValue
        
        let rate = service.masteryRate(for: [mastered1, mastered2, vague, none])
        
        #expect(rate == 0.5) // 2 out of 4
    }
    
    @Test("Mastery rate for empty array")
    func testMasteryRateEmpty() {
        let rate = service.masteryRate(for: [])
        #expect(rate == 0)
    }
    
    @Test("Average review count calculation")
    func testAverageReviewCount() {
        let item1 = createTestItem()
        item1.reviewCount = 10
        
        let item2 = createTestItem()
        item2.reviewCount = 20
        
        let average = service.averageReviewCount(for: [item1, item2])
        
        #expect(average == 15) // (10 + 20) / 2
    }
    
    @Test("Average review count for empty array")
    func testAverageReviewCountEmpty() {
        let average = service.averageReviewCount(for: [])
        #expect(average == 0)
    }
    
    // MARK: - Edge Cases
    
    @Test("Custom scheduler is used")
    func testCustomScheduler() {
        let customScheduler = ReviewScheduler()
        let customService = ReviewService(scheduler: customScheduler)
        let item = createTestItem()
        
        customService.recordReview(for: item, performance: .basic)
        
        #expect(item.reviewCount == 1)
    }
    
    @Test("Shared instance is available")
    func testSharedInstance() {
        let shared = ReviewService.shared
        let item = createTestItem()
        
        shared.recordReview(for: item, performance: .basic)
        
        #expect(item.reviewCount == 1)
    }
    
    // MARK: - Value Object Boundary Tests
    
    @Test("Subject value object conversion")
    func testSubjectValueObjectConversion() {
        let item = createTestItem()
        item.subject = .math
        
        #expect(item.subjectRaw == Subject.math.rawValue)
        #expect(item.subject == .math)
    }
    
    @Test("ReviewPerformance value object boundary")
    func testReviewPerformanceBoundary() {
        let item = createTestItem()
        
        service.recordReview(for: item, performance: ReviewPerformance.forgot)
        #expect(item.mastery == .none)
        
        service.recordReview(for: item, performance: ReviewPerformance.easy)
        #expect(item.masteryLevel == 4)
    }
    
    // MARK: - Helper
    
    private func createTestItem() -> ReviewItemModel {
        ReviewItemModel(
            title: "Test Question",
            note: "Test Answer",
            subjectRaw: Subject.other.rawValue
        )
    }
}
