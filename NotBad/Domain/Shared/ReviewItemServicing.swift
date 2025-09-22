//
//  ReviewItemServicing.swift
//  NotBad
//
//  Created by GitHub Copilot on 9/22/25.
//

import Foundation

/// 领域服务协议：为可替换性与测试隔离提供抽象
protocol ReviewItemServicing {
    func createReviewItem(
        question: String,
        answer: String,
        subject: String,
        difficulty: String,
        tags: [String],
        notes: String?
    ) async throws -> ReviewItemID

    func getReviewItem(id: ReviewItemID) async throws -> ReviewItem?
    func updateReviewItem(id: ReviewItemID, updates: ReviewItemUpdates) async throws
    func deleteReviewItem(id: ReviewItemID) async throws
    func recordReviewResult(id: ReviewItemID, wasSuccessful: Bool) async throws
    func getItemsForReview(date: Date, limit: Int) async throws -> [ReviewItem]
    func getAllItems() async throws -> [ReviewItem]
    func searchReviewItems(query: String, limit: Int) async throws -> [ReviewItem]
    func getItemsByCriteria(_ criteria: ReviewItemQueryCriteria) async throws -> [ReviewItem]
    func getStatistics() async throws -> ReviewItemStatistics
}
