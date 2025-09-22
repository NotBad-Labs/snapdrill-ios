//
//  ReviewItemService.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// ReviewItem 领域服务
/// 遵循DDD原则，协调复杂的业务操作，使用Repository进行数据访问
final class ReviewItemService {
    
    // MARK: - Dependencies
    private let repository: ReviewItemRepository
    
    // MARK: - Initialization
    init(repository: ReviewItemRepository) {
        self.repository = repository
    }
    
    // MARK: - 业务操作
    
    /// 创建复习项
    func createReviewItem(
        question: String,
        answer: String,
        subject: String,
        difficulty: String,
        tags: [String],
        notes: String?
    ) async throws -> ReviewItemID {
        // 1. 创建领域对象，自动进行业务规则验证
        let subjectEnum = ReviewItem.Subject(rawValue: subject) ?? .other
        let difficultyEnum = ReviewItem.Difficulty(rawValue: difficulty) ?? .medium
        
        let item = try ReviewItem(
            question: question,
            answer: answer,
            subject: subjectEnum,
            difficulty: difficultyEnum,
            tags: Set(tags),
            notes: notes
        )
        
        // 2. 通过仓储保存
        return try await repository.save(item)
    }
    
    /// 获取复习项
    func getReviewItem(id: ReviewItemID) async throws -> ReviewItem? {
        return try await repository.findById(id)
    }
    
    /// 更新复习项
    func updateReviewItem(id: ReviewItemID, updates: ReviewItemUpdates) async throws {
        // 1. 检查项目是否存在
        guard try await repository.exists(id) else {
            throw RepositoryError.itemNotFound(id)
        }
        
        // 2. 执行更新
        _ = try await repository.update(id, with: updates)
    }
    
    /// 删除复习项
    func deleteReviewItem(id: ReviewItemID) async throws {
        try await repository.delete(id)
    }
    
    /// 记录复习结果
    func recordReviewResult(id: ReviewItemID, wasSuccessful: Bool) async throws {
        // 1. 获取当前项目
        guard let item = try await repository.findById(id) else {
            throw RepositoryError.itemNotFound(id)
        }
        
        // 2. 创建新的复习会话记录
        let session = ReviewSession(
            date: Date(),
            wasSuccessful: wasSuccessful,
            difficulty: item.difficulty
        )
        
        // 3. 更新复习历史和熟练度
        var updatedItem = item
        updatedItem.addReviewSession(session)
        
        // 4. 保存更新
        _ = try await repository.save(updatedItem)
    }
    
    /// 获取需要复习的项目
    func getItemsForReview(date: Date, limit: Int) async throws -> [ReviewItem] {
        return try await repository.findItemsForReview(on: date, limit: limit)
    }
    
    /// 获取所有复习项
    func getAllItems() async throws -> [ReviewItem] {
        return try await repository.findAll()
    }
    
    /// 搜索复习项
    func searchReviewItems(query: String, limit: Int) async throws -> [ReviewItem] {
        return try await repository.search(query: query, limit: limit)
    }
    
    /// 按条件获取复习项
    func getItemsByCriteria(_ criteria: ReviewItemQueryCriteria) async throws -> [ReviewItem] {
        return try await repository.findBy(criteria)
    }
    
    /// 获取统计信息
    func getStatistics() async throws -> ReviewItemStatistics {
        let total = try await repository.count()
        
        let easyCount = try await repository.count(by: ReviewItemQueryCriteria(difficulty: .easy))
        let mediumCount = try await repository.count(by: ReviewItemQueryCriteria(difficulty: .medium))
        let hardCount = try await repository.count(by: ReviewItemQueryCriteria(difficulty: .hard))
        
        let notProficientCount = try await repository.count(by: ReviewItemQueryCriteria(proficiencyLevel: .notProficient))
        let learningCount = try await repository.count(by: ReviewItemQueryCriteria(proficiencyLevel: .learning))
        let proficientCount = try await repository.count(by: ReviewItemQueryCriteria(proficiencyLevel: .proficient))
        
        return ReviewItemStatistics(
            total: total,
            difficultyBreakdown: DifficultyBreakdown(
                easy: easyCount,
                medium: mediumCount,
                hard: hardCount
            ),
            proficiencyBreakdown: ProficiencyBreakdown(
                notProficient: notProficientCount,
                learning: learningCount,
                proficient: proficientCount
            )
        )
    }
}

// MARK: - 统计相关值对象

/// 复习项统计信息
struct ReviewItemStatistics {
    let total: Int
    let difficultyBreakdown: DifficultyBreakdown
    let proficiencyBreakdown: ProficiencyBreakdown
    
    var averageDifficulty: Double {
        let totalWithDifficulty = difficultyBreakdown.easy + difficultyBreakdown.medium + difficultyBreakdown.hard
        guard totalWithDifficulty > 0 else { return 0 }
        
        let weightedSum = difficultyBreakdown.easy * 1 + difficultyBreakdown.medium * 2 + difficultyBreakdown.hard * 3
        return Double(weightedSum) / Double(totalWithDifficulty)
    }
    
    var proficiencyRate: Double {
        guard total > 0 else { return 0 }
        return Double(proficiencyBreakdown.proficient) / Double(total)
    }
}

/// 难度分布
struct DifficultyBreakdown {
    let easy: Int
    let medium: Int
    let hard: Int
}

/// 熟练度分布
struct ProficiencyBreakdown {
    let notProficient: Int
    let learning: Int
    let proficient: Int
}

/// ReviewItem ID 值对象
struct ReviewItemID: Hashable, Codable {
    let value: UUID
    
    init() {
        self.value = UUID()
    }
    
    init(_ uuid: UUID) {
        self.value = uuid
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.value = try container.decode(UUID.self)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

/// ReviewItem 更新结构
struct ReviewItemUpdates {
    let question: String?
    let answer: String?
    let subject: String?
    let difficulty: String?
    let tags: [String]?
    let notes: String?
    
    init(
        question: String? = nil,
        answer: String? = nil,
        subject: String? = nil,
        difficulty: String? = nil,
        tags: [String]? = nil,
        notes: String? = nil
    ) {
        self.question = question
        self.answer = answer
        self.subject = subject
        self.difficulty = difficulty
        self.tags = tags
        self.notes = notes
    }
}