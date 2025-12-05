//
//  ReviewItemRepository.swift
//  NotBad
//
//  错题记录仓储实现
//

import Foundation
import SwiftData

/// 错题记录仓储实现
/// 使用 ReviewItemModel 进行 SwiftData 持久化，对外暴露纯领域实体 ReviewItem
@MainActor
final class ReviewItemRepository: Sendable {
    
    // MARK: - Properties
    
    private let modelContext: ModelContext
    private let modelContainer: ModelContainer
    
    // MARK: - Initialization
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        self.modelContext = modelContainer.mainContext
    }
    
    // MARK: - CRUD Operations
    
    /// 获取所有错题
    func fetchAll() -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch all review items: \(error)")
            return []
        }
    }
    
    /// 根据 ID 获取单个错题
    func fetch(by id: UUID) -> ReviewItem? {
        guard let model = fetchModel(by: id) else { return nil }
        return ReviewItemMapper.toEntity(from: model)
    }
    
    /// 根据 ID 获取持久化模型
    private func fetchModel(by id: UUID) -> ReviewItemModel? {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.id == id
            }
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.first
        } catch {
            print("Failed to fetch model by id: \(error)")
            return nil
        }
    }
    
    /// 保存或更新错题
    func save(_ item: ReviewItem) throws {
        if let existingModel = fetchModel(by: item.id) {
            // 更新现有模型
            ReviewItemMapper.updateModel(existingModel, from: item)
        } else {
            // 创建新模型
            let newModel = ReviewItemMapper.toModel(from: item)
            modelContext.insert(newModel)
        }
        
        try modelContext.save()
    }
    
    /// 批量保存错题
    func saveAll(_ items: [ReviewItem]) throws {
        for item in items {
            try save(item)
        }
    }
    
    /// 删除错题
    func delete(_ item: ReviewItem) throws {
        guard let model = fetchModel(by: item.id) else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
    
    /// 根据 ID 删除错题
    func delete(by id: UUID) throws {
        guard let model = fetchModel(by: id) else { return }
        modelContext.delete(model)
        try modelContext.save()
    }
    
    /// 批量删除错题
    func deleteAll(_ items: [ReviewItem]) throws {
        for item in items {
            try delete(item)
        }
    }
    
    /// 删除所有错题
    func deleteAll() throws {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        let models = try modelContext.fetch(descriptor)
        
        for model in models {
            modelContext.delete(model)
        }
        
        try modelContext.save()
    }
    
    // MARK: - Query Operations
    
    /// 根据学科获取错题
    func fetch(by subject: Subject) -> [ReviewItem] {
        let subjectRaw = subject.rawValue
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.subjectRaw == subjectRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch review items by subject: \(error)")
            return []
        }
    }
    
    /// 根据掌握程度获取错题
    func fetch(by masteryLevel: MasteryLevel) -> [ReviewItem] {
        let levelRaw = masteryLevel.rawValue
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.masteryLevel == levelRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch review items by mastery level: \(error)")
            return []
        }
    }
    
    /// 获取收藏的错题
    func fetchFavorites() -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.isFavorite == true
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch favorite items: \(error)")
            return []
        }
    }
    
    /// 获取需要复习的错题（根据下次复习日期）
    func fetchDueForReview() -> [ReviewItem] {
        let now = Date()
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.nextReviewDate <= now
            },
            sortBy: [SortDescriptor(\.nextReviewDate, order: .forward)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch items due for review: \(error)")
            return []
        }
    }
    
    /// 获取今日添加的错题
    func fetchTodayItems() -> [ReviewItem] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.createdAt >= startOfDay && model.createdAt < endOfDay
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch today's items: \(error)")
            return []
        }
    }
    
    /// 获取最近添加的错题
    func fetchRecent(limit: Int = 10) -> [ReviewItem] {
        var descriptor = FetchDescriptor<ReviewItemModel>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch recent items: \(error)")
            return []
        }
    }
    
    /// 根据日期范围获取错题
    func fetch(from startDate: Date, to endDate: Date) -> [ReviewItem] {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.createdAt >= startDate && model.createdAt <= endDate
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch items in date range: \(error)")
            return []
        }
    }
    
    /// 根据错误类型获取错题
    func fetch(by errorType: ErrorType) -> [ReviewItem] {
        let typeRaw = errorType.rawValue
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.errorTypeRaw == typeRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch items by error type: \(error)")
            return []
        }
    }
    
    /// 根据来源获取错题
    func fetch(by source: Source) -> [ReviewItem] {
        let sourceRaw = source.rawValue
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.sourceRaw == sourceRaw
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to fetch items by source: \(error)")
            return []
        }
    }
    
    // MARK: - Search Operations
    
    /// 搜索错题（按关键词）
    func search(query keyword: String) -> [ReviewItem] {
        let lowercasedKeyword = keyword.lowercased()
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.subjectRaw.localizedStandardContains(lowercasedKeyword) ||
                model.note.localizedStandardContains(lowercasedKeyword) ||
                model.title.localizedStandardContains(lowercasedKeyword)
            },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        do {
            let models = try modelContext.fetch(descriptor)
            return models.map { ReviewItemMapper.toEntity(from: $0) }
        } catch {
            print("Failed to search items: \(error)")
            return []
        }
    }
    
    // MARK: - Statistics
    
    /// 获取错题总数
    func count() -> Int {
        let descriptor = FetchDescriptor<ReviewItemModel>()
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Failed to count items: \(error)")
            return 0
        }
    }
    
    /// 获取各学科错题数量
    func countBySubject() -> [Subject: Int] {
        let items = fetchAll()
        var result: [Subject: Int] = [:]
        for item in items {
            result[item.subject, default: 0] += 1
        }
        return result
    }
    
    /// 获取各掌握程度错题数量
    func countByMasteryLevel() -> [MasteryLevel: Int] {
        let items = fetchAll()
        var result: [MasteryLevel: Int] = [:]
        for item in items {
            result[item.mastery, default: 0] += 1
        }
        return result
    }
    
    /// 获取各错误类型错题数量
    func countByErrorType() -> [ErrorType: Int] {
        let items = fetchAll()
        var result: [ErrorType: Int] = [:]
        for item in items {
            result[item.errorType, default: 0] += 1
        }
        return result
    }
    
    /// 获取收藏数量
    func countFavorites() -> Int {
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.isFavorite == true
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Failed to count favorites: \(error)")
            return 0
        }
    }
    
    /// 获取快速统计数据
    /// 使用高效的 fetchCount，适合首页等需要快速显示的场景
    func quickStatistics() -> (total: Int, pendingReview: Int, mastered: Int) {
        let total = count()
        let pendingReview = countDueForReview()
        
        // 计算已掌握数量（good 或 mastered）
        let masteredLevelRaw = MasteryLevel.mastered.rawValue
        let goodLevelRaw = MasteryLevel.good.rawValue
        let masteredDescriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.masteryLevel == masteredLevelRaw || model.masteryLevel == goodLevelRaw
            }
        )
        let mastered = (try? modelContext.fetchCount(masteredDescriptor)) ?? 0
        
        return (total, pendingReview, mastered)
    }
    
    /// 获取今日添加数量
    func countTodayItems() -> Int {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.createdAt >= startOfDay && model.createdAt < endOfDay
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Failed to count today's items: \(error)")
            return 0
        }
    }
    
    /// 获取待复习数量
    func countDueForReview() -> Int {
        let now = Date()
        let descriptor = FetchDescriptor<ReviewItemModel>(
            predicate: #Predicate<ReviewItemModel> { model in
                model.nextReviewDate <= now
            }
        )
        do {
            return try modelContext.fetchCount(descriptor)
        } catch {
            print("Failed to count items due for review: \(error)")
            return 0
        }
    }
    
    // MARK: - Batch Operations
    
    /// 批量更新掌握程度
    func updateMasteryLevel(for ids: [UUID], to level: MasteryLevel) throws {
        let levelRaw = level.rawValue
        for id in ids {
            if let model = fetchModel(by: id) {
                model.masteryLevel = levelRaw
                model.updatedAt = Date()
            }
        }
        try modelContext.save()
    }
    
    /// 批量切换收藏状态
    func toggleFavorite(for ids: [UUID]) throws {
        for id in ids {
            if let model = fetchModel(by: id) {
                model.isFavorite.toggle()
                model.updatedAt = Date()
            }
        }
        try modelContext.save()
    }
    
    // MARK: - Migration Support
    
    /// 获取底层 ModelContext（仅用于迁移）
    var underlyingModelContext: ModelContext {
        modelContext
    }
    
    /// 获取底层 ModelContainer（仅用于迁移）
    var underlyingModelContainer: ModelContainer {
        modelContainer
    }
}

// MARK: - ReviewItemRepositoryProtocol Conformance

extension ReviewItemRepository: ReviewItemRepositoryProtocol {
    
    /// 根据条件筛选错题
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem] {
        var items = fetchAll()
        
        if let subject = subject {
            items = items.filter { $0.subject == subject }
        }
        
        if let mastery = mastery {
            items = items.filter { $0.mastery == mastery }
        }
        
        return items
    }
    
    /// 获取需要复习的错题（protocol 要求的方法名）
    func fetchForReview() -> [ReviewItem] {
        fetchDueForReview()
    }
    
    /// 批量删除错题
    func delete(_ items: [ReviewItem]) throws {
        try deleteAll(items)
    }
    
    /// 获取统计数据
    func statistics() -> ReviewStatistics {
        let items = fetchAll()
        return ReviewStatistics(from: items)
    }
}
