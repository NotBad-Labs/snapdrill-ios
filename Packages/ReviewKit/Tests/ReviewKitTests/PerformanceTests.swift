import XCTest
@testable import ReviewKit

@MainActor
final class PerformanceTests: XCTestCase {
    func testBatchMarkAsMasteredPerformance() {
        let service = ReviewService()
        let items = (0..<1_000).map { _ in ReviewItemModel() }
        measure {
            service.markAsMastered(items: items)
        }
    }
}
