//
//  ReviewItemDataTypes.swift
//  NotBad
//
//  Created by AI Assistant on 2025/9/13.
//

import Foundation

// MARK: - 复习项数据类型定义
/// 复习项相关的所有请求和响应数据结构
/// 遵循Clean Architecture的数据传输对象(DTO)设计原则

// MARK: - 复习项过滤条件
/// 复习项查询的过滤条件
public enum ReviewItemFilter: Codable {
    case all
    case byOwner(UUID)
    case bySubject(String)
    case byMasteryLevel(MasteryLevel)
    case byDifficulty(DifficultyLevel)
    case byTags([String])
    case byDateRange(DateRange)
    case bySearch(String)
    case custom(CustomReviewItemFilter)
}

// MARK: - 自定义过滤条件
/// 自定义的复习项过滤条件
public struct CustomReviewItemFilter: Codable {
    let ownerId: UUID?
    let subject: String?
    let masteryLevel: MasteryLevel?
    let difficulty: DifficultyLevel?
    let tags: [String]?
    let dateRange: DateRange?
    
    init(
        ownerId: UUID? = nil,
        subject: String? = nil,
        masteryLevel: MasteryLevel? = nil,
        difficulty: DifficultyLevel? = nil,
        tags: [String]? = nil,
        dateRange: DateRange? = nil
    ) {
        self.ownerId = ownerId
        self.subject = subject
        self.masteryLevel = masteryLevel
        self.difficulty = difficulty
        self.tags = tags
        self.dateRange = dateRange
    }
}

// MARK: - 日期范围
/// 日期范围结构
public struct DateRange: Codable {
    let startDate: Date
    let endDate: Date
    
    init(startDate: Date, endDate: Date) {
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - 复习项排序方式
/// 复习项排序方式
public enum ReviewItemSortBy: String, CaseIterable, Codable {
    case createdDateAsc = "created_date_asc"
    case createdDateDesc = "created_date_desc"
    case updatedDateAsc = "updated_date_asc"
    case updatedDateDesc = "updated_date_desc"
    case titleAsc = "title_asc"
    case titleDesc = "title_desc"
    case masteryLevel = "mastery_level"
    case difficulty = "difficulty"
    
    var displayName: String {
        switch self {
        case .createdDateAsc:
            return "创建时间（升序）"
        case .createdDateDesc:
            return "创建时间（降序）"
        case .updatedDateAsc:
            return "更新时间（升序）"
        case .updatedDateDesc:
            return "更新时间（降序）"
        case .titleAsc:
            return "标题（升序）"
        case .titleDesc:
            return "标题（降序）"
        case .masteryLevel:
            return "掌握程度"
        case .difficulty:
            return "难度等级"
        }
    }
}

// MARK: - 复习项统计信息
/// 复习项统计信息
struct ReviewItemStatistics: Codable {
    let totalCount: Int
    let masteryLevelCounts: [MasteryLevel: Int]
    let difficultyLevelCounts: [DifficultyLevel: Int]
    let subjectCounts: [String: Int]
    
    init(
        totalCount: Int,
        masteryLevelCounts: [MasteryLevel: Int],
        difficultyLevelCounts: [DifficultyLevel: Int],
        subjectCounts: [String: Int]
    ) {
        self.totalCount = totalCount
        self.masteryLevelCounts = masteryLevelCounts
        self.difficultyLevelCounts = difficultyLevelCounts
        self.subjectCounts = subjectCounts
    }
}

// MARK: - 创建复习项请求和响应
/// 创建复习项请求
public struct CreateReviewItemRequest: Codable {
    let title: String
    let question: String
    let answer: String?
    let explanation: String?
    let imageData: Data?
    let subject: String
    let difficulty: DifficultyLevel
    let tags: [String]
    let ownerId: UUID
    let source: ItemSource
    
    init(
        title: String,
        question: String,
        answer: String? = nil,
        explanation: String? = nil,
        imageData: Data? = nil,
        subject: String,
        difficulty: DifficultyLevel = .medium,
        tags: [String] = [],
        ownerId: UUID,
        source: ItemSource = .manual
    ) {
        self.title = title
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.imageData = imageData
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.ownerId = ownerId
        self.source = source
    }
}

/// 创建复习项响应
public struct CreateReviewItemResponse: Codable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
    let timestamp: Date
    
    init(reviewItem: ReviewItem, success: Bool = true, message: String? = nil) {
        self.reviewItem = reviewItem
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - 获取复习项请求和响应
/// 获取复习项列表请求
public struct GetReviewItemsRequest: Codable {
    let filter: ReviewItemFilter
    let sortBy: ReviewItemSortBy
    let page: Int
    let pageSize: Int
    
    init(
        filter: ReviewItemFilter = .all,
        sortBy: ReviewItemSortBy = .createdDateDesc,
        page: Int = 0,
        pageSize: Int = 20
    ) {
        self.filter = filter
        self.sortBy = sortBy
        self.page = page
        self.pageSize = pageSize
    }
}

/// 获取复习项列表响应
public struct GetReviewItemsResponse: Codable {
    let items: [ReviewItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasNextPage: Bool
    let statistics: ReviewItemStatistics
    let timestamp: Date
    
    init(
        items: [ReviewItem],
        totalCount: Int,
        page: Int,
        pageSize: Int,
        statistics: ReviewItemStatistics
    ) {
        self.items = items
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
        self.hasNextPage = (page + 1) * pageSize < totalCount
        self.statistics = statistics
        self.timestamp = Date()
    }
}

// MARK: - 更新复习项请求和响应
/// 更新复习项请求
public struct UpdateReviewItemRequest: Codable {
    let id: UUID
    let title: String?
    let question: String?
    let answer: String?
    let explanation: String?
    let imageData: Data?
    let subject: String?
    let difficulty: DifficultyLevel?
    let tags: [String]?
    let masteryLevel: MasteryLevel?
    
    init(
        id: UUID,
        title: String? = nil,
        question: String? = nil,
        answer: String? = nil,
        explanation: String? = nil,
        imageData: Data? = nil,
        subject: String? = nil,
        difficulty: DifficultyLevel? = nil,
        tags: [String]? = nil,
        masteryLevel: MasteryLevel? = nil
    ) {
        self.id = id
        self.title = title
        self.question = question
        self.answer = answer
        self.explanation = explanation
        self.imageData = imageData
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.masteryLevel = masteryLevel
    }
}

/// 更新复习项响应
public struct UpdateReviewItemResponse: Codable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
    let timestamp: Date
    
    init(reviewItem: ReviewItem, success: Bool = true, message: String? = nil) {
        self.reviewItem = reviewItem
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - 删除复习项请求和响应
/// 删除复习项请求
public struct DeleteReviewItemRequest: Codable {
    let id: UUID
    let reason: String?
    
    init(id: UUID, reason: String? = nil) {
        self.id = id
        self.reason = reason
    }
}

/// 删除复习项响应
public struct DeleteReviewItemResponse: Codable {
    let success: Bool
    let message: String?
    let timestamp: Date
    
    init(success: Bool = true, message: String? = nil) {
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - 学习记录请求和响应
/// 添加学习记录请求
public struct AddStudyRecordRequest: Codable {
    let reviewItemId: UUID
    let isCorrect: Bool
    let timeSpent: TimeInterval
    let notes: String?
    
    init(
        reviewItemId: UUID,
        isCorrect: Bool,
        timeSpent: TimeInterval,
        notes: String? = nil
    ) {
        self.reviewItemId = reviewItemId
        self.isCorrect = isCorrect
        self.timeSpent = timeSpent
        self.notes = notes
    }
}

/// 添加学习记录响应
public struct AddStudyRecordResponse: Codable {
    let reviewItem: ReviewItem
    let studyRecord: StudyRecord
    let success: Bool
    let message: String?
    let timestamp: Date
    
    init(
        reviewItem: ReviewItem,
        studyRecord: StudyRecord,
        success: Bool = true,
        message: String? = nil
    ) {
        self.reviewItem = reviewItem
        self.studyRecord = studyRecord
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - 更新掌握程度请求和响应
/// 更新掌握程度请求
public struct UpdateMasteryLevelRequest: Codable {
    let reviewItemId: UUID
    let masteryLevel: MasteryLevel
    let reason: String?
    
    init(reviewItemId: UUID, masteryLevel: MasteryLevel, reason: String? = nil) {
        self.reviewItemId = reviewItemId
        self.masteryLevel = masteryLevel
        self.reason = reason
    }
}

/// 更新掌握程度响应
public struct UpdateMasteryLevelResponse: Codable {
    let reviewItem: ReviewItem
    let success: Bool
    let message: String?
    let timestamp: Date
    
    init(reviewItem: ReviewItem, success: Bool = true, message: String? = nil) {
        self.reviewItem = reviewItem
        self.success = success
        self.message = message
        self.timestamp = Date()
    }
}

// MARK: - 搜索复习项请求和响应
/// 搜索复习项请求
public struct SearchReviewItemsRequest: Codable {
    let query: String
    let filters: ReviewItemFilter?
    let sortBy: ReviewItemSortBy
    let page: Int
    let pageSize: Int
    
    init(
        query: String,
        filters: ReviewItemFilter? = nil,
        sortBy: ReviewItemSortBy = .createdDateDesc,
        page: Int = 0,
        pageSize: Int = 20
    ) {
        self.query = query
        self.filters = filters
        self.sortBy = sortBy
        self.page = page
        self.pageSize = pageSize
    }
}

/// 搜索复习项响应
public struct SearchReviewItemsResponse: Codable {
    let items: [ReviewItem]
    let totalCount: Int
    let page: Int
    let pageSize: Int
    let hasNextPage: Bool
    let searchQuery: String
    let timestamp: Date
    
    init(
        items: [ReviewItem],
        totalCount: Int,
        page: Int,
        pageSize: Int,
        searchQuery: String
    ) {
        self.items = items
        self.totalCount = totalCount
        self.page = page
        self.pageSize = pageSize
        self.hasNextPage = (page + 1) * pageSize < totalCount
        self.searchQuery = searchQuery
        self.timestamp = Date()
    }
}

// MARK: - 获取统计信息请求和响应
/// 获取统计信息请求
public struct GetStatisticsRequest: Codable {
    let ownerId: UUID?
    let dateRange: DateRange?
    let groupBy: StatisticsGroupBy
    
    init(
        ownerId: UUID? = nil,
        dateRange: DateRange? = nil,
        groupBy: StatisticsGroupBy = .subject
    ) {
        self.ownerId = ownerId
        self.dateRange = dateRange
        self.groupBy = groupBy
    }
}

/// 获取统计信息响应
public struct GetStatisticsResponse: Codable {
    let statistics: ReviewItemStatistics
    let subjectStatistics: [String: Int]
    let masteryStatistics: [MasteryLevel: Int]
    let difficultyStatistics: [DifficultyLevel: Int]
    let timeRangeStatistics: [String: Int]
    let timestamp: Date
    
    init(
        statistics: ReviewItemStatistics,
        subjectStatistics: [String: Int],
        masteryStatistics: [MasteryLevel: Int],
        difficultyStatistics: [DifficultyLevel: Int],
        timeRangeStatistics: [String: Int]
    ) {
        self.statistics = statistics
        self.subjectStatistics = subjectStatistics
        self.masteryStatistics = masteryStatistics
        self.difficultyStatistics = difficultyStatistics
        self.timeRangeStatistics = timeRangeStatistics
        self.timestamp = Date()
    }
}

// MARK: - 批量操作请求和响应
/// 批量创建复习项请求
public struct CreateReviewItemsBatchRequest: Codable {
    let items: [CreateReviewItemRequest]
    let ownerId: UUID
    
    init(items: [CreateReviewItemRequest], ownerId: UUID) {
        self.items = items
        self.ownerId = ownerId
    }
}

/// 批量创建复习项响应
public struct CreateReviewItemsBatchResponse: Codable {
    let createdItems: [ReviewItem]
    let failedItems: [FailedItem]
    let successCount: Int
    let failureCount: Int
    let timestamp: Date
    
    init(createdItems: [ReviewItem], failedItems: [FailedItem]) {
        self.createdItems = createdItems
        self.failedItems = failedItems
        self.successCount = createdItems.count
        self.failureCount = failedItems.count
        self.timestamp = Date()
    }
}

/// 批量更新复习项请求
public struct UpdateReviewItemsBatchRequest: Codable {
    let updates: [UpdateReviewItemRequest]
    
    init(updates: [UpdateReviewItemRequest]) {
        self.updates = updates
    }
}

/// 批量更新复习项响应
public struct UpdateReviewItemsBatchResponse: Codable {
    let updatedItems: [ReviewItem]
    let failedItems: [FailedItem]
    let successCount: Int
    let failureCount: Int
    let timestamp: Date
    
    init(updatedItems: [ReviewItem], failedItems: [FailedItem]) {
        self.updatedItems = updatedItems
        self.failedItems = failedItems
        self.successCount = updatedItems.count
        self.failureCount = failedItems.count
        self.timestamp = Date()
    }
}

/// 批量删除复习项请求
public struct DeleteReviewItemsBatchRequest: Codable {
    let ids: [UUID]
    let reason: String?
    
    init(ids: [UUID], reason: String? = nil) {
        self.ids = ids
        self.reason = reason
    }
}

/// 批量删除复习项响应
public struct DeleteReviewItemsBatchResponse: Codable {
    let deletedIds: [UUID]
    let failedItems: [FailedItem]
    let successCount: Int
    let failureCount: Int
    let timestamp: Date
    
    init(deletedIds: [UUID], failedItems: [FailedItem]) {
        self.deletedIds = deletedIds
        self.failedItems = failedItems
        self.successCount = deletedIds.count
        self.failureCount = failedItems.count
        self.timestamp = Date()
    }
}

// MARK: - 辅助数据结构
/// 失败的项目
struct FailedItem: Codable {
    let id: UUID?
    let reason: String
    let error: String
    
    init(id: UUID? = nil, reason: String, error: String) {
        self.id = id
        self.reason = reason
        self.error = error
    }
}

/// 统计分组方式
public enum StatisticsGroupBy: String, CaseIterable, Codable {
    case subject = "subject"
    case masteryLevel = "mastery_level"
    case difficulty = "difficulty"
    case date = "date"
    case week = "week"
    case month = "month"
    
    var displayName: String {
        switch self {
        case .subject:
            return "按科目"
        case .masteryLevel:
            return "按掌握程度"
        case .difficulty:
            return "按难度"
        case .date:
            return "按日期"
        case .week:
            return "按周"
        case .month:
            return "按月"
        }
    }
}
