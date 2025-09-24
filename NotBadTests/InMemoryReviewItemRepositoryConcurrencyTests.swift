//
//  InMemoryReviewItemRepositoryConcurrencyTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class InMemoryReviewItemRepositoryConcurrencyTests: XCTestCase {
    func testConcurrentSaveAndCount_NoDataRaces() async throws {
        let repo = InMemoryReviewItemRepository()

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    let item = try! ReviewItem(
                        question: "Q\(i)",
                        answer: "A\(i)",
                        subject: .other,
                        difficulty: .easy
                    )
                    _ = try! await repo.save(item)
                }
            }
        }

        let c = try await repo.count()
        XCTAssertEqual(c, 50)
    }

    func testConcurrentFindAndSearch_NoCrash() async throws {
        let repo = InMemoryReviewItemRepository()
        // Seed
        for i in 0..<30 {
            let item = try ReviewItem(
                question: "Integral \(i)",
                answer: "∫\(i)",
                subject: .math,
                difficulty: .medium
            )
            _ = try await repo.save(item)
        }

        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    _ = try! await repo.findAll()
                }
                group.addTask {
                    _ = try! await repo.search(query: "∫", limit: 5)
                }
            }
        }

        // Basic sanity
        let limited = try await repo.search(query: "Integral", limit: 10)
        XCTAssertEqual(limited.count, 10)
    }

    func testConcurrentUpdateAndExists_NoCrash() async throws {
        let repo = InMemoryReviewItemRepository()
        var base = try ReviewItem(
            question: "Base",
            answer: "A",
            subject: .english,
            difficulty: .medium
        )
        let id = try await repo.save(base)

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<20 {
                group.addTask {
                    let updates = ReviewItemUpdates(
                        question: "B\(i)",
                        answer: nil,
                        subject: nil,
                        difficulty: nil,
                        tags: nil,
                        notes: nil
                    )
                    _ = try! await repo.update(id, with: updates)
                }
                group.addTask {
                    _ = try! await repo.exists(id)
                }
            }
        }

        let final = try await repo.findById(id)
        XCTAssertNotNil(final)
    }
}
