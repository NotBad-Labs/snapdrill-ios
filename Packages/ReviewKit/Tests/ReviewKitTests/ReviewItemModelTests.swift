import XCTest
@testable import ReviewKit

@MainActor
final class ReviewItemModelTests: XCTestCase {
    
    let service = ReviewService()
    
    // MARK: - recordReview (via ReviewService)
    func testRecordReviewUpdatesCoreFields() {
        let item = ReviewItemModel(title: "题目", note: "笔记")
        service.recordReview(for: item, performance: 2)
        XCTAssertEqual(item.masteryLevel, 2)
        XCTAssertEqual(item.reviewCount, 1)
        let days = Calendar.current.dateComponents([.day], from: Date(), to: item.nextReviewDate).day!
        XCTAssertEqual(days, 1)
    }
    
    func testRecordReviewClampsPerformanceBounds() {
        let item = ReviewItemModel()
        service.recordReview(for: item, performance: -5)
        XCTAssertEqual(item.masteryLevel, 0)
        service.recordReview(for: item, performance: 9)
        XCTAssertEqual(item.masteryLevel, 4)
    }
    
    // MARK: - Accessors
    func testKnowledgePointsAccessor() {
        let item = ReviewItemModel()
        item.knowledgePoints = ["函数", "导数"]
        XCTAssertEqual(item.knowledgePoints, ["函数", "导数"])
        item.knowledgePoints = []
        XCTAssertEqual(item.knowledgePoints, [])
    }
    
    func testDisplayTitleFallback() {
        let item = ReviewItemModel(title: "", note: "")
        XCTAssertEqual(item.displayTitle, "未命名错题")
    }
    
    // MARK: - Reset (via ReviewService)
    func testResetProgress() {
        let item = ReviewItemModel()
        service.recordReview(for: item, performance: 3)
        service.resetProgress(for: item)
        XCTAssertEqual(item.masteryLevel, 0)
        XCTAssertEqual(item.reviewCount, 0)
        XCTAssertLessThan(abs(item.nextReviewDate.timeIntervalSinceNow), 1)
    }
}
