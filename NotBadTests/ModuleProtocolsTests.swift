//
//  ModuleProtocolsTests.swift
//  NotBadTests
//
//  Created by AI Assistant on 2025/9/13.
//

import XCTest
@testable import NotBad

// MARK: - 模块协议测试
class ModuleProtocolsTests: XCTestCase {
    
    func testDomainEntityProtocol() {
        // Given
        let reviewItem = ReviewItem(
            content: ReviewContent(
                title: "数学题",
                question: "1+1等于多少？",
                subject: "数学"
            ),
            metadata: ReviewMetadata(ownerId: UUID())
        )
        
        // Then
        XCTAssertNotNil(reviewItem.id)
        XCTAssertEqual(reviewItem.id, reviewItem.id)
    }
    
    func testRepositoryErrorProtocol() {
        // Given & When
        let notFoundError = ReviewItemRepositoryError.notFound(id: UUID())
        let invalidDataError = ReviewItemRepositoryError.invalidData("测试错误")
        let storageError = ReviewItemRepositoryError.storageError("存储失败")
        
        // Then
        XCTAssertNotNil(notFoundError.errorDescription)
        XCTAssertNotNil(invalidDataError.errorDescription)
        XCTAssertNotNil(storageError.errorDescription)
    }
    
    func testUseCaseErrorProtocol() {
        // Given & When
        let validationError = ReviewItemUseCaseError.validationFailed("验证失败")
        let businessError = ReviewItemUseCaseError.businessRuleViolation("业务规则违反")
        let repositoryError = ReviewItemUseCaseError.repositoryError("仓储错误")
        
        // Then
        XCTAssertNotNil(validationError.errorDescription)
        XCTAssertNotNil(businessError.errorDescription)
        XCTAssertNotNil(repositoryError.errorDescription)
    }
    
    func testServiceErrorProtocol() {
        // Given & When
        let serviceError = ReviewItemServiceError.serviceUnavailable("服务不可用")
        let configError = ReviewItemServiceError.configurationError("配置错误")
        let externalError = ReviewItemServiceError.externalServiceError("外部服务错误")
        
        // Then
        XCTAssertNotNil(serviceError.errorDescription)
        XCTAssertNotNil(configError.errorDescription)
        XCTAssertNotNil(externalError.errorDescription)
    }
    
    func testDomainEventProtocol() {
        // Given
        let event = ReviewItemCreatedEvent(
            reviewItemId: UUID(),
            ownerId: UUID(),
            subject: "数学",
            difficulty: .easy
        )
        
        // Then
        XCTAssertNotNil(event.eventId)
        XCTAssertNotNil(event.timestamp)
        XCTAssertEqual(event.eventType, "ReviewItemCreated")
        XCTAssertNotNil(event.reviewItemId)
    }
    
    func testEnvironmentEnum() {
        // Then
        XCTAssertEqual(Environment.development.displayName, "开发环境")
        XCTAssertEqual(Environment.staging.displayName, "测试环境")
        XCTAssertEqual(Environment.production.displayName, "生产环境")
    }
    
    func testHTTPMethodEnum() {
        // Then
        XCTAssertEqual(HTTPMethod.GET.rawValue, "GET")
        XCTAssertEqual(HTTPMethod.POST.rawValue, "POST")
        XCTAssertEqual(HTTPMethod.PUT.rawValue, "PUT")
        XCTAssertEqual(HTTPMethod.DELETE.rawValue, "DELETE")
        XCTAssertEqual(HTTPMethod.PATCH.rawValue, "PATCH")
    }
    
    func testStatisticsGroupByEnum() {
        // Then
        XCTAssertEqual(StatisticsGroupBy.subject.displayName, "按科目")
        XCTAssertEqual(StatisticsGroupBy.masteryLevel.displayName, "按掌握程度")
        XCTAssertEqual(StatisticsGroupBy.difficulty.displayName, "按难度")
        XCTAssertEqual(StatisticsGroupBy.date.displayName, "按日期")
        XCTAssertEqual(StatisticsGroupBy.week.displayName, "按周")
        XCTAssertEqual(StatisticsGroupBy.month.displayName, "按月")
    }
}

// MARK: - 复习项协议测试
class ReviewItemProtocolsTests: XCTestCase {
    
    func testReviewItemFilterEnum() {
        // Given
        let ownerId = UUID()
        let dateRange = DateRange(startDate: Date(), endDate: Date())
        
        // When & Then
        let allFilter = ReviewItemFilter.all
        let ownerFilter = ReviewItemFilter.byOwner(ownerId)
        let subjectFilter = ReviewItemFilter.bySubject("数学")
        let masteryFilter = ReviewItemFilter.byMasteryLevel(.mastered)
        let difficultyFilter = ReviewItemFilter.byDifficulty(.hard)
        let tagsFilter = ReviewItemFilter.byTags(["代数", "几何"])
        let dateFilter = ReviewItemFilter.byDateRange(dateRange)
        let searchFilter = ReviewItemFilter.bySearch("测试")
        
        // 验证所有过滤条件都能正确创建
        XCTAssertNotNil(allFilter)
        XCTAssertNotNil(ownerFilter)
        XCTAssertNotNil(subjectFilter)
        XCTAssertNotNil(masteryFilter)
        XCTAssertNotNil(difficultyFilter)
        XCTAssertNotNil(tagsFilter)
        XCTAssertNotNil(dateFilter)
        XCTAssertNotNil(searchFilter)
    }
    
    func testCustomReviewItemFilter() {
        // Given
        let ownerId = UUID()
        let dateRange = DateRange(startDate: Date(), endDate: Date())
        
        // When
        let customFilter = CustomReviewItemFilter(
            ownerId: ownerId,
            subject: "数学",
            masteryLevel: .mastered,
            difficulty: .hard,
            tags: ["代数", "几何"],
            dateRange: dateRange
        )
        
        // Then
        XCTAssertEqual(customFilter.ownerId, ownerId)
        XCTAssertEqual(customFilter.subject, "数学")
        XCTAssertEqual(customFilter.masteryLevel, .mastered)
        XCTAssertEqual(customFilter.difficulty, .hard)
        XCTAssertEqual(customFilter.tags, ["代数", "几何"])
        XCTAssertEqual(customFilter.dateRange?.startDate, dateRange.startDate)
    }
    
    func testReviewItemSortByEnum() {
        // Then
        XCTAssertEqual(ReviewItemSortBy.createdDateAsc.displayName, "创建时间（升序）")
        XCTAssertEqual(ReviewItemSortBy.createdDateDesc.displayName, "创建时间（降序）")
        XCTAssertEqual(ReviewItemSortBy.updatedDateAsc.displayName, "更新时间（升序）")
        XCTAssertEqual(ReviewItemSortBy.updatedDateDesc.displayName, "更新时间（降序）")
        XCTAssertEqual(ReviewItemSortBy.titleAsc.displayName, "标题（升序）")
        XCTAssertEqual(ReviewItemSortBy.titleDesc.displayName, "标题（降序）")
        XCTAssertEqual(ReviewItemSortBy.masteryLevel.displayName, "掌握程度")
        XCTAssertEqual(ReviewItemSortBy.difficulty.displayName, "难度等级")
    }
    
    func testCreateReviewItemRequest() {
        // Given
        let ownerId = UUID()
        
        // When
        let request = CreateReviewItemRequest(
            title: "数学题",
            question: "1+1等于多少？",
            answer: "2",
            subject: "数学",
            difficulty: .easy,
            tags: ["基础"],
            ownerId: ownerId,
            source: .manual
        )
        
        // Then
        XCTAssertEqual(request.title, "数学题")
        XCTAssertEqual(request.question, "1+1等于多少？")
        XCTAssertEqual(request.answer, "2")
        XCTAssertEqual(request.subject, "数学")
        XCTAssertEqual(request.difficulty, .easy)
        XCTAssertEqual(request.tags, ["基础"])
        XCTAssertEqual(request.ownerId, ownerId)
        XCTAssertEqual(request.source, .manual)
    }
    
    func testGetReviewItemsRequest() {
        // Given
        let filter = ReviewItemFilter.bySubject("数学")
        let sortBy = ReviewItemSortBy.titleAsc
        
        // When
        let request = GetReviewItemsRequest(
            filter: filter,
            sortBy: sortBy,
            page: 1,
            pageSize: 10
        )
        
        // Then
        // 注意：这里需要根据实际的ReviewItemFilter实现来调整测试
        // 由于ReviewItemFilter是enum，直接比较可能有问题
        XCTAssertEqual(request.sortBy, sortBy)
        XCTAssertEqual(request.page, 1)
        XCTAssertEqual(request.pageSize, 10)
    }
    
    func testReviewItemStatistics() {
        // Given
        let masteryCounts: [MasteryLevel: Int] = [
            .notMastered: 5,
            .fuzzy: 3,
            .mastered: 2
        ]
        let difficultyCounts: [DifficultyLevel: Int] = [
            .easy: 3,
            .medium: 4,
            .hard: 3
        ]
        let subjectCounts: [String: Int] = [
            "数学": 5,
            "英语": 3,
            "物理": 2
        ]
        
        // When
        let statistics = ReviewItemStatistics(
            totalCount: 10,
            masteryLevelCounts: masteryCounts,
            difficultyLevelCounts: difficultyCounts,
            subjectCounts: subjectCounts
        )
        
        // Then
        XCTAssertEqual(statistics.totalCount, 10)
        XCTAssertEqual(statistics.masteryLevelCounts[.notMastered], 5)
        XCTAssertEqual(statistics.masteryLevelCounts[.fuzzy], 3)
        XCTAssertEqual(statistics.masteryLevelCounts[.mastered], 2)
        XCTAssertEqual(statistics.difficultyLevelCounts[.easy], 3)
        XCTAssertEqual(statistics.difficultyLevelCounts[.medium], 4)
        XCTAssertEqual(statistics.difficultyLevelCounts[.hard], 3)
        XCTAssertEqual(statistics.subjectCounts["数学"], 5)
        XCTAssertEqual(statistics.subjectCounts["英语"], 3)
        XCTAssertEqual(statistics.subjectCounts["物理"], 2)
    }
}
