import XCTest
@testable import ReviewKit

final class ReviewItemModelTests: XCTestCase {
    // MARK: - recordReview
    func testRecordReviewUpdatesCoreFields() {
        let item = ReviewItemModel(title: "题目", note: "笔记")
        item.recordReview(performance: 2)
        XCTAssertEqual(item.masteryLevel, 2)
        XCTAssertEqual(item.reviewCount, 1)
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.nextReviewDate).day!
        XCTAssertEqual(days, 1)
    }
    
    func testRecordReviewClampsPerformanceBounds() {
        let item = ReviewItemModel()
        item.recordReview(performance: -5)
        XCTAssertEqual(item.masteryLevel, 0)
        item.recordReview(performance: 9)
        XCTAssertEqual(item.masteryLevel, 3)
    }
    
    // MARK: - Accessors
    func testKnowledgePointsAccessor() {
        let item = ReviewItemModel()
        item.knowledgePoints = ["函数", "导数"]
        XCTAssertEqual(item.knowledgePointsRaw, "函数,导数")
        item.knowledgePoints = []
        XCTAssertEqual(item.knowledgePointsRaw, "")
    }
    
    func testDisplayTitleFallback() {
        let item = ReviewItemModel(title: "", note: "")
        XCTAssertEqual(item.displayTitle, "未命名错题")
    }
    
    // MARK: - Reset
    func testResetProgress() {
        let item = ReviewItemModel()
        item.recordReview(performance: 3)
        item.resetProgress()
        XCTAssertEqual(item.masteryLevel, 0)
        XCTAssertEqual(item.reviewCount, 0)
        XCTAssertLessThan(abs(item.nextReviewDate.timeIntervalSinceNow), 1)
    }
}
