//
//  ReviewItemServiceProtocols.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 复习项服务协议
/// 复习项相关的所有服务协议定义
/// 遵循接口驱动设计，实现模块间高度解耦

// MARK: - 复习项仓储协议
/// 复习项数据访问协议
protocol ReviewItemRepository {
    typealias Entity = ReviewItem
    typealias ID = UUID
    typealias Error = ReviewItemRepositoryError
    
    // MARK: - 基础CRUD操作
    /// 创建新的复习项
    func create(_ item: ReviewItem) async throws -> ReviewItem
    
    /// 根据ID获取复习项
    func getById(_ id: UUID) async throws -> ReviewItem?
    
    /// 获取所有复习项
    func getAll() async throws -> [ReviewItem]
    
    /// 更新复习项
    func update(_ item: ReviewItem) async throws -> ReviewItem
    
    /// 删除复习项
    func delete(_ id: UUID) async throws
    
    /// 批量删除复习项
    func deleteBatch(_ ids: [UUID]) async throws
    
    // MARK: - 查询操作
    /// 根据用户ID获取复习项
    func getByOwner(_ ownerId: UUID) async throws -> [ReviewItem]
    
    /// 根据科目获取复习项
    func getBySubject(_ subject: String) async throws -> [ReviewItem]
    
    /// 根据掌握程度获取复习项
    func getByMasteryLevel(_ masteryLevel: MasteryLevel) async throws -> [ReviewItem]
    
    /// 根据难度等级获取复习项
    func getByDifficulty(_ difficulty: DifficultyLevel) async throws -> [ReviewItem]
    
    /// 根据标签获取复习项
    func getByTags(_ tags: [String]) async throws -> [ReviewItem]
    
    /// 根据日期范围获取复习项
    func getByDateRange(_ dateRange: DateRange) async throws -> [ReviewItem]
    
    /// 搜索复习项
    func search(_ query: String) async throws -> [ReviewItem]
    
    // MARK: - 学习记录操作
    /// 添加学习记录
    func addStudyRecord(itemId: UUID, record: StudyRecord) async throws -> ReviewItem
    
    /// 更新掌握程度
    func updateMasteryLevel(itemId: UUID, masteryLevel: MasteryLevel) async throws -> ReviewItem
    
    /// 获取学习历史
    func getStudyHistory(itemId: UUID) async throws -> [StudyRecord]
    
    // MARK: - 统计操作
    /// 获取复习项统计信息
    func getStatistics(ownerId: UUID?) async throws -> ReviewItemStatistics
    
    /// 获取科目统计
    func getSubjectStatistics(ownerId: UUID?) async throws -> [String: Int]
    
    /// 获取掌握程度统计
    func getMasteryStatistics(ownerId: UUID?) async throws -> [MasteryLevel: Int]
}

// MARK: - 复习项用例协议
/// 复习项业务用例协议
protocol ReviewItemUseCase {
    associatedtype Request
    associatedtype Response
    
    func execute(_ request: Request) async throws -> Response
}

// MARK: - 创建复习项用例协议
protocol CreateReviewItemUseCase: ReviewItemUseCase where Request == CreateReviewItemRequest, Response == CreateReviewItemResponse {
    func execute(_ request: Request) async throws -> Response
}

// MARK: - 获取复习项用例协议
protocol GetReviewItemsUseCase: ReviewItemUseCase where Request == GetReviewItemsRequest, Response == GetReviewItemsResponse {
    func execute(_ request: Request) async throws -> Response
}

// MARK: - 更新复习项用例协议
protocol UpdateReviewItemUseCase: ReviewItemUseCase where Request == UpdateReviewItemRequest, Response == UpdateReviewItemResponse {
    func execute(_ request: Request) async throws -> Response
}

// MARK: - 删除复习项用例协议
protocol DeleteReviewItemUseCase: ReviewItemUseCase where Request == DeleteReviewItemRequest, Response == DeleteReviewItemResponse {
    
    func execute(_ request: Request) async throws -> Response
}

// MARK: - 复习项服务协议
/// 复习项业务服务协议
protocol ReviewItemService {
    typealias Error = ReviewItemServiceError
    
    // MARK: - 业务操作
    /// 创建复习项
    func createReviewItem(_ request: CreateReviewItemRequest) async throws -> CreateReviewItemResponse
    
    /// 获取复习项列表
    func getReviewItems(_ request: GetReviewItemsRequest) async throws -> GetReviewItemsResponse
    
    /// 更新复习项
    func updateReviewItem(_ request: UpdateReviewItemRequest) async throws -> UpdateReviewItemResponse
    
    /// 删除复习项
    func deleteReviewItem(_ request: DeleteReviewItemRequest) async throws -> DeleteReviewItemResponse
    
    /// 添加学习记录
    func addStudyRecord(_ request: AddStudyRecordRequest) async throws -> AddStudyRecordResponse
    
    /// 更新掌握程度
    func updateMasteryLevel(_ request: UpdateMasteryLevelRequest) async throws -> UpdateMasteryLevelResponse
    
    // MARK: - 查询操作
    /// 搜索复习项
    func searchReviewItems(_ request: SearchReviewItemsRequest) async throws -> SearchReviewItemsResponse
    
    /// 获取统计信息
    func getStatistics(_ request: GetStatisticsRequest) async throws -> GetStatisticsResponse
    
    // MARK: - 批量操作
    /// 批量创建复习项
    func createReviewItemsBatch(_ request: CreateReviewItemsBatchRequest) async throws -> CreateReviewItemsBatchResponse
    
    /// 批量更新复习项
    func updateReviewItemsBatch(_ request: UpdateReviewItemsBatchRequest) async throws -> UpdateReviewItemsBatchResponse
    
    /// 批量删除复习项
    func deleteReviewItemsBatch(_ request: DeleteReviewItemsBatchRequest) async throws -> DeleteReviewItemsBatchResponse
}

// MARK: - 复习项事件协议
/// 复习项相关事件协议
protocol ReviewItemEvent {
    var reviewItemId: UUID { get }
}

/// 复习项创建事件
struct ReviewItemCreatedEvent: ReviewItemEvent {
    let eventId: UUID = UUID()
    let timestamp: Date = Date()
    let eventType: String = "ReviewItemCreated"
    let reviewItemId: UUID
    let ownerId: UUID
    let subject: String
    let difficulty: DifficultyLevel
}

/// 复习项更新事件
struct ReviewItemUpdatedEvent: ReviewItemEvent {
    let eventId: UUID = UUID()
    let timestamp: Date = Date()
    let eventType: String = "ReviewItemUpdated"
    let reviewItemId: UUID
    let changes: [String: Any]
}

/// 复习项删除事件
struct ReviewItemDeletedEvent: ReviewItemEvent {
    let eventId: UUID = UUID()
    let timestamp: Date = Date()
    let eventType: String = "ReviewItemDeleted"
    let reviewItemId: UUID
    let ownerId: UUID
}

/// 学习记录添加事件
struct StudyRecordAddedEvent: ReviewItemEvent {
    let eventId: UUID = UUID()
    let timestamp: Date = Date()
    let eventType: String = "StudyRecordAdded"
    let reviewItemId: UUID
    let recordId: UUID
    let isCorrect: Bool
    let masteryLevel: MasteryLevel
}

// MARK: - 复习项错误类型
/// 复习项仓储错误
enum ReviewItemRepositoryError: Error, LocalizedError {
    case itemNotFound(UUID)
    case itemAlreadyExists(UUID)
    case invalidData(String)
    case storageError(String)
    case networkError(String)
    case permissionDenied(String)
    
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound(let id):
            return "复习项未找到: \(id)"
        case .itemAlreadyExists(let id):
            return "复习项已存在: \(id)"
        case .invalidData(let message):
            return "数据无效: \(message)"
        case .storageError(let message):
            return "存储错误: \(message)"
        case .networkError(let message):
            return "网络错误: \(message)"
        case .permissionDenied(let message):
            return "权限不足: \(message)"
        }
    }
}

/// 复习项用例错误
enum ReviewItemUseCaseError: Error, LocalizedError {
    case validationFailed(String)
    case businessRuleViolation(String)
    case repositoryError(String)
    
    
    var errorDescription: String? {
        switch self {
        case .validationFailed(let message):
            return "验证失败: \(message)"
        case .businessRuleViolation(let message):
            return "业务规则违反: \(message)"
        case .repositoryError(let message):
            return "仓储错误: \(message)"
        }
    }
}

/// 复习项服务错误
enum ReviewItemServiceError: Error, LocalizedError {
    case serviceUnavailable(String)
    case configurationError(String)
    case externalServiceError(String)
    
    
    var errorDescription: String? {
        switch self {
        case .serviceUnavailable(let message):
            return "服务不可用: \(message)"
        case .configurationError(let message):
            return "配置错误: \(message)"
        case .externalServiceError(let message):
            return "外部服务错误: \(message)"
        }
    }
}
