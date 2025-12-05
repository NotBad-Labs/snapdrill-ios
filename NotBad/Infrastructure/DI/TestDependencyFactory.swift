//
//  TestDependencyFactory.swift
//  NotBad
//
//  测试环境依赖工厂 - 使用 Mock 实现
//

import Foundation
import UIKit

// MARK: - TestDependencyFactory

/// 测试环境依赖工厂
///
/// 创建 Mock 依赖，用于单元测试和 UI 测试。
///
/// ## 使用示例
///
/// ```swift
/// @Test
/// func testStartReviewSession() async throws {
///     let factory = TestDependencyFactory()
///     let useCase = factory.makeStartReviewSessionUseCase()
///     
///     let session = try await useCase.execute(mode: .smart)
///     #expect(!session.isEmpty)
/// }
/// ```
@MainActor
final class TestDependencyFactory: DependencyFactory {
    
    // MARK: - Mock Instances
    
    /// Mock 错题数据
    var mockItems: [ReviewItem] = []
    
    /// Mock Repository
    private lazy var mockRepository: MockReviewItemRepository = {
        let repo = MockReviewItemRepository()
        repo.items = mockItems
        return repo
    }()
    
    // MARK: - Initialization
    
    init(mockItems: [ReviewItem] = []) {
        self.mockItems = mockItems
    }
    
    // MARK: - Repositories
    
    func makeReviewItemRepository() -> ReviewItemRepositoryProtocol {
        mockRepository
    }
    
    // MARK: - Use Cases - Review
    
    func makeStartReviewSessionUseCase() -> StartReviewSessionUseCaseProtocol {
        StartReviewSessionUseCase(repository: mockRepository)
    }
    
    func makeRecordReviewResultUseCase() -> RecordReviewResultUseCaseProtocol {
        fatalError("RecordReviewResultUseCase not implemented yet")
    }
    
    func makeCompleteReviewSessionUseCase() -> CompleteReviewSessionUseCaseProtocol {
        CompleteReviewSessionUseCase(repository: mockRepository)
    }
    
    // MARK: - Use Cases - Library
    
    func makeCreateReviewItemUseCase() -> CreateReviewItemUseCaseProtocol {
        CreateReviewItemUseCase(repository: mockRepository)
    }
    
    func makeDeleteReviewItemUseCase() -> DeleteReviewItemUseCaseProtocol {
        DeleteReviewItemUseCase(repository: mockRepository)
    }
    
    func makeFetchReviewItemsUseCase() -> FetchReviewItemsUseCaseProtocol {
        FetchReviewItemsUseCase(repository: mockRepository)
    }
    
    // MARK: - Use Cases - Statistics
    
    func makeGetStatisticsUseCase() -> GetStatisticsUseCaseProtocol {
        fatalError("GetStatisticsUseCase not implemented yet")
    }
    
    // MARK: - Services
    
    func makeOCRService() -> any OCRServiceProtocol {
        MockOCRService()
    }
    
    func makeAnalyticsService() -> any AnalyticsServiceProtocol {
        MockAnalyticsService()
    }
}

// MARK: - MockReviewItemRepository

/// Mock 错题仓库
///
/// 内存存储，用于测试。
@MainActor
final class MockReviewItemRepository: ReviewItemRepositoryProtocol {
    
    // MARK: - Properties
    
    var items: [ReviewItem] = []
    
    /// 模拟错误
    var shouldThrowError: Bool = false
    var errorToThrow: Error = NSError(domain: "Mock", code: -1)
    
    // MARK: - Fetch Operations
    
    func fetchAll() -> [ReviewItem] {
        items
    }
    
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem] {
        var result = items
        if let subject = subject {
            result = result.filter { $0.subject == subject }
        }
        if let mastery = mastery {
            result = result.filter { $0.masteryLevel == mastery.rawValue }
        }
        return result
    }
    
    func fetchForReview() -> [ReviewItem] {
        items.filter { $0.nextReviewDate <= Date() }
    }
    
    func fetchForReview(subject: Subject) -> [ReviewItem] {
        fetchForReview().filter { $0.subject == subject }
    }
    
    func fetchDueToday() -> [ReviewItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return items.filter { $0.nextReviewDate >= today && $0.nextReviewDate < tomorrow }
    }
    
    func fetchDueThisWeek() -> [ReviewItem] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: today)!
        return items.filter { $0.nextReviewDate >= today && $0.nextReviewDate < weekEnd }
    }
    
    func fetchOverdue() -> [ReviewItem] {
        items.filter { $0.nextReviewDate < Date() }
    }
    
    // MARK: - Search Operations
    
    func search(query: String) -> [ReviewItem] {
        let lowercasedQuery = query.lowercased()
        return items.filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.note.lowercased().contains(lowercasedQuery)
        }
    }
    
    func search(byKnowledgePoint knowledgePoint: String) -> [ReviewItem] {
        items.filter { $0.knowledgePointsRaw.contains(knowledgePoint) }
    }
    
    // MARK: - CRUD Operations
    
    func save(_ item: ReviewItem) throws {
        if shouldThrowError { throw errorToThrow }
        
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
        } else {
            items.append(item)
        }
    }
    
    func save(_ items: [ReviewItem]) throws {
        for item in items {
            try save(item)
        }
    }
    
    func delete(_ item: ReviewItem) throws {
        if shouldThrowError { throw errorToThrow }
        items.removeAll { $0.id == item.id }
    }
    
    func delete(_ items: [ReviewItem]) throws {
        for item in items {
            try delete(item)
        }
    }
    
    func deleteAll() throws {
        if shouldThrowError { throw errorToThrow }
        items.removeAll()
    }
    
    // MARK: - Statistics
    
    func statistics() -> ReviewStatistics {
        ReviewStatistics(
            totalCount: items.count,
            masteredCount: items.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }.count,
            weeklyNewCount: 0,
            totalReviewCount: items.reduce(0) { $0 + $1.reviewCount },
            pendingReviewCount: fetchForReview().count,
            overdueCount: items.filter { $0.isOverdue }.count,
            masteryDistribution: [:],
            subjectDistribution: [:],
            difficultyDistribution: [:]
        )
    }
    
    func statistics(for subject: Subject) -> ReviewStatistics {
        let subjectItems = items.filter { $0.subject == subject }
        return ReviewStatistics(
            totalCount: subjectItems.count,
            masteredCount: subjectItems.filter { $0.masteryLevel == MasteryLevel.mastered.rawValue }.count,
            weeklyNewCount: 0,
            totalReviewCount: subjectItems.reduce(0) { $0 + $1.reviewCount },
            pendingReviewCount: subjectItems.filter { $0.nextReviewDate <= Date() }.count,
            overdueCount: subjectItems.filter { $0.isOverdue }.count,
            masteryDistribution: [:],
            subjectDistribution: [:],
            difficultyDistribution: [:]
        )
    }
}

// MARK: - MockOCRService

/// Mock OCR 服务
@MainActor
final class MockOCRService: OCRServiceProtocol {
    
    var mockText: String = "Mock OCR Text"
    var mockConfidence: Double = 0.95
    var shouldThrowError: Bool = false
    
    func recognizeText(from image: UIImage) async throws -> String {
        if shouldThrowError {
            throw NSError(domain: "MockOCR", code: -1)
        }
        return mockText
    }
    
    func recognizeTextWithConfidence(from image: UIImage) async throws -> OCRResult {
        if shouldThrowError {
            throw NSError(domain: "MockOCR", code: -1)
        }
        return OCRResult(text: mockText, lines: [], confidence: mockConfidence)
    }
}

// MARK: - MockAnalyticsService

/// Mock 分析服务
@MainActor
final class MockAnalyticsService: AnalyticsServiceProtocol {
    
    var trackedEvents: [AnalyticsEvent] = []
    var userProperties: [String: String] = [:]
    var userId: String?
    
    func track(_ event: AnalyticsEvent) {
        trackedEvents.append(event)
    }
    
    func track(_ name: String, parameters: [String: String]) {
        trackedEvents.append(AnalyticsEvent(name: name, parameters: parameters))
    }
    
    func setUserProperty(_ value: String, forName name: String) {
        userProperties[name] = value
    }
    
    func setUserId(_ userId: String?) {
        self.userId = userId
    }
}
