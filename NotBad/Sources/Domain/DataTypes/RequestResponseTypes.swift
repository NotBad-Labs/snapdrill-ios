//
//  RequestResponseTypes.swift
//  NotBad
//
//  Created by Swift 6 Upgrade Script on 2025/9/13.
//

import Foundation

// MARK: - 请求/响应类型定义
// 为Swift 6并发安全提供Sendable协议支持

// MARK: - 创建复习项请求/响应
struct CreateReviewItemRequest: Sendable {
    let content: ReviewContent
    let metadata: ReviewMetadata
    let ownerId: UUID
}

struct CreateReviewItemResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 获取复习项请求/响应
struct GetReviewItemsRequest: Sendable {
    let ownerId: UUID?
    let subject: String?
    let masteryLevel: MasteryLevel?
    let difficulty: DifficultyLevel?
    let tags: [String]?
    let dateRange: DateRange?
    let searchQuery: String?
    let limit: Int?
    let offset: Int?
}

struct GetReviewItemsResponse: Sendable {
    let reviewItems: [ReviewItem]
    let totalCount: Int
    let hasMore: Bool
}

// MARK: - 更新复习项请求/响应
struct UpdateReviewItemRequest: Sendable {
    let id: UUID
    let content: ReviewContent?
    let metadata: ReviewMetadata?
    let masteryLevel: MasteryLevel?
}

struct UpdateReviewItemResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 删除复习项请求/响应
struct DeleteReviewItemRequest: Sendable {
    let id: UUID
}

struct DeleteReviewItemResponse: Sendable {
    let success: Bool
    let message: String?
}

// MARK: - 添加学习记录请求/响应
struct AddStudyRecordRequest: Sendable {
    let itemId: UUID
    let record: StudyRecord
}

struct AddStudyRecordResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 更新掌握程度请求/响应
struct UpdateMasteryLevelRequest: Sendable {
    let itemId: UUID
    let masteryLevel: MasteryLevel
}

struct UpdateMasteryLevelResponse: Sendable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
}

// MARK: - 搜索复习项请求/响应
struct SearchReviewItemsRequest: Sendable {
    let query: String
    let ownerId: UUID?
    let subject: String?
    let limit: Int?
}

struct SearchReviewItemsResponse: Sendable {
    let reviewItems: [ReviewItem]
    let totalCount: Int
}

// MARK: - 获取统计信息请求/响应
struct GetStatisticsRequest: Sendable {
    let ownerId: UUID?
    let dateRange: DateRange?
}

struct GetStatisticsResponse: Sendable {
    let statistics: ReviewItemStatistics
    let subjectStatistics: [String: Int]
    let masteryStatistics: [MasteryLevel: Int]
}

// MARK: - 批量操作请求/响应
struct CreateReviewItemsBatchRequest: Sendable {
    let items: [CreateReviewItemRequest]
}

struct CreateReviewItemsBatchResponse: Sendable {
    let reviewItems: [ReviewItem]
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}

struct UpdateReviewItemsBatchRequest: Sendable {
    let updates: [UpdateReviewItemRequest]
}

struct UpdateReviewItemsBatchResponse: Sendable {
    let reviewItems: [ReviewItem]
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}

struct DeleteReviewItemsBatchRequest: Sendable {
    let ids: [UUID]
}

struct DeleteReviewItemsBatchResponse: Sendable {
    let successCount: Int
    let failureCount: Int
    let errors: [String]
}
