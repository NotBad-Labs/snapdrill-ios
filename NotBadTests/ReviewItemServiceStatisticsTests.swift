import XCTest
@testable import NotBad

final class ReviewItemServiceStatisticsTests: XCTestCase {
    func testStatisticsOnEmptyRepository_returnsZeros() async throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)

        let stats = try await service.getStatistics()

        XCTAssertEqual(stats.total, 0)
        XCTAssertEqual(stats.difficultyBreakdown.easy, 0)
        XCTAssertEqual(stats.difficultyBreakdown.medium, 0)
        XCTAssertEqual(stats.difficultyBreakdown.hard, 0)
        XCTAssertEqual(stats.proficiencyBreakdown.notProficient, 0)
        XCTAssertEqual(stats.proficiencyBreakdown.learning, 0)
        XCTAssertEqual(stats.proficiencyBreakdown.proficient, 0)
        XCTAssertEqual(stats.averageDifficulty, 0.0, accuracy: 0.0001)
        XCTAssertEqual(stats.proficiencyRate, 0.0, accuracy: 0.0001)
    }

    func testStatisticsAfterCreatingItems_countsAndAverages() async throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)

        _ = try await service.createReviewItem(
            question: "Q1",
            answer: "A1",
            subject: "math",
            difficulty: "easy",
            tags: ["algebra"],
            notes: nil
        )

        _ = try await service.createReviewItem(
            question: "Q2",
            answer: "A2",
            subject: "science",
            difficulty: "medium",
            tags: ["physics"],
            notes: nil
        )

        _ = try await service.createReviewItem(
            question: "Q3",
            answer: "A3",
            subject: "language",
            difficulty: "hard",
            tags: ["vocab"],
            notes: nil
        )

        let stats = try await service.getStatistics()

        XCTAssertEqual(stats.total, 3)
        XCTAssertEqual(stats.difficultyBreakdown.easy, 1)
        XCTAssertEqual(stats.difficultyBreakdown.medium, 1)
        XCTAssertEqual(stats.difficultyBreakdown.hard, 1)
        // 初始熟练度应全部为 notProficient
        XCTAssertEqual(stats.proficiencyBreakdown.notProficient, 3)
        XCTAssertEqual(stats.proficiencyBreakdown.learning, 0)
        XCTAssertEqual(stats.proficiencyBreakdown.proficient, 0)
        XCTAssertEqual(stats.averageDifficulty, 2.0, accuracy: 0.0001) // (1+2+3)/3
        XCTAssertEqual(stats.proficiencyRate, 0.0, accuracy: 0.0001)
    }
}
