import XCTest
@testable import NotBad

final class ReviewItemServiceUpdateValidationTests: XCTestCase {
    func testUpdateReviewItem_withInvalidSubjectOrDifficulty_ignoresInvalidValues() async throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let id = try await service.createReviewItem(
            question: "Q",
            answer: "A",
            subject: "math",
            difficulty: "medium",
            tags: [],
            notes: nil
        )

        // Try to update subject/difficulty with invalid raw values (should be ignored)
        try await service.updateReviewItem(
            id: id,
            updates: ReviewItemUpdates(subject: "invalid-subject", difficulty: "invalid-difficulty")
        )

        let fetched = try await service.getReviewItem(id: id)
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.subject, .math) // unchanged
        XCTAssertEqual(fetched?.difficulty, .medium) // unchanged
    }

    func testUpdateReviewItem_itemNotFound_throws() async throws {
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let missing = ReviewItemID()
        await XCTAssertThrowsErrorAsync(try await service.updateReviewItem(id: missing, updates: ReviewItemUpdates(question: "Q2")))
    }
}

// Helper to assert async throwing
func XCTAssertThrowsErrorAsync<T>(_ expression: @autoclosure () async throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #filePath, line: UInt = #line) async {
    do {
        _ = try await expression()
        XCTFail(message(), file: file, line: line)
    } catch {
        // expected
    }
}
