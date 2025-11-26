//
//  ReviewItemRepositoryTests.swift
//  NotBadTests
//
//  仓库层单元测试
//

import Testing
import Foundation
import SwiftData
@testable import NotBad

@Suite("ReviewItemRepository 测试")
@MainActor
struct ReviewItemRepositoryTests {
    
    // MARK: - 测试辅助
    
    /// 创建内存中的测试容器
    private func createTestContainer() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: ReviewItem.self, configurations: config)
    }
    
    /// 创建测试仓库
    private func createRepository() throws -> (ReviewItemRepository, ModelContainer) {
        let container = try createTestContainer()
        let context = container.mainContext
        let repository = ReviewItemRepository(modelContext: context)
        return (repository, container)
    }
    
    /// 创建测试用的错题
    private func createTestItem(
        title: String = "测试题",
        subject: Subject = .math,
        mastery: MasteryLevel = .partial,
        difficulty: Difficulty = .medium,
        source: Source = .homework
    ) -> ReviewItem {
        ReviewItem(
            title: title,
            mastery: mastery,
            subject: subject,
            difficulty: difficulty,
            source: source
        )
    }
    
    // MARK: - 保存测试
    
    @Test("保存新错题成功")
    func saveNewItem() throws {
        let (repository, _) = try createRepository()
        
        let item = createTestItem()
        try repository.save(item)
        
        let allItems = repository.fetchAll()
        #expect(allItems.count == 1)
        #expect(allItems.first?.title == "测试题")
    }
    
    @Test("保存多个错题成功")
    func saveMultipleItems() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "数学题1", subject: .math))
        try repository.save(createTestItem(title: "物理题1", subject: .physics))
        try repository.save(createTestItem(title: "化学题1", subject: .chemistry))
        
        let allItems = repository.fetchAll()
        #expect(allItems.count == 3)
    }
    
    // MARK: - 查询测试
    
    @Test("fetchAll 返回所有错题")
    func fetchAllItems() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "题1"))
        try repository.save(createTestItem(title: "题2"))
        try repository.save(createTestItem(title: "题3"))
        
        let allItems = repository.fetchAll()
        #expect(allItems.count == 3)
    }
    
    @Test("fetchAll 按创建时间降序排列")
    func fetchAllSortedByCreatedAt() throws {
        let (repository, _) = try createRepository()
        
        // 创建两个项目，手动设置不同的创建时间
        let item1 = createTestItem(title: "第一题")
        let item2 = createTestItem(title: "第二题")
        
        // 让 item1 的创建时间更早
        item1.createdAt = Date().addingTimeInterval(-3600) // 1小时前
        item2.createdAt = Date() // 现在
        
        try repository.save(item1)
        try repository.save(item2)
        
        let allItems = repository.fetchAll()
        #expect(allItems.count == 2)
        // 最新的在前
        #expect(allItems.first?.title == "第二题")
    }
    
    @Test("fetch(byId:) 返回正确的错题")
    func fetchById() throws {
        let (repository, _) = try createRepository()
        
        let item = createTestItem(title: "唯一题目")
        try repository.save(item)
        
        let fetchedItem = repository.fetch(byId: item.id)
        #expect(fetchedItem != nil)
        #expect(fetchedItem?.title == "唯一题目")
    }
    
    @Test("fetch(byId:) 不存在时返回 nil")
    func fetchByIdNotFound() throws {
        let (repository, _) = try createRepository()
        
        let fetchedItem = repository.fetch(byId: UUID())
        #expect(fetchedItem == nil)
    }
    
    // MARK: - 筛选测试
    
    @Test("按学科筛选")
    func fetchBySubject() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "数学1", subject: .math))
        try repository.save(createTestItem(title: "数学2", subject: .math))
        try repository.save(createTestItem(title: "物理1", subject: .physics))
        
        let mathItems = repository.fetch(subject: .math)
        #expect(mathItems.count == 2)
        
        let physicsItems = repository.fetch(subject: .physics)
        #expect(physicsItems.count == 1)
    }
    
    @Test("按掌握程度筛选")
    func fetchByMastery() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "未掌握", mastery: .none))
        try repository.save(createTestItem(title: "部分掌握1", mastery: .partial))
        try repository.save(createTestItem(title: "部分掌握2", mastery: .partial))
        try repository.save(createTestItem(title: "已掌握", mastery: .mastered))
        
        let partialItems = repository.fetch(subject: nil, mastery: .partial)
        #expect(partialItems.count == 2)
        
        let masteredItems = repository.fetch(subject: nil, mastery: .mastered)
        #expect(masteredItems.count == 1)
    }
    
    @Test("按学科和掌握程度联合筛选")
    func fetchBySubjectAndMastery() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "数学-部分", subject: .math, mastery: .partial))
        try repository.save(createTestItem(title: "数学-掌握", subject: .math, mastery: .mastered))
        try repository.save(createTestItem(title: "物理-部分", subject: .physics, mastery: .partial))
        
        let items = repository.fetch(subject: .math, mastery: .partial)
        #expect(items.count == 1)
        #expect(items.first?.title == "数学-部分")
    }
    
    @Test("按难度筛选")
    func fetchByDifficulty() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "简单题", difficulty: .easy))
        try repository.save(createTestItem(title: "中等题1", difficulty: .medium))
        try repository.save(createTestItem(title: "中等题2", difficulty: .medium))
        try repository.save(createTestItem(title: "困难题", difficulty: .hard))
        
        let mediumItems = repository.fetch(difficulty: .medium)
        #expect(mediumItems.count == 2)
    }
    
    @Test("按来源筛选")
    func fetchBySource() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "作业题", source: .homework))
        try repository.save(createTestItem(title: "考试题1", source: .exam))
        try repository.save(createTestItem(title: "考试题2", source: .exam))
        
        let examItems = repository.fetch(source: .exam)
        #expect(examItems.count == 2)
    }
    
    // MARK: - 复习相关测试
    
    @Test("fetchForReview 返回需要复习的错题")
    func fetchForReview() throws {
        let (repository, _) = try createRepository()
        
        // 需要复习的
        let item1 = createTestItem(title: "需复习1", mastery: .none)
        item1.nextReviewDate = Date().addingTimeInterval(-86400) // 昨天
        try repository.save(item1)
        
        let item2 = createTestItem(title: "需复习2", mastery: .partial)
        item2.nextReviewDate = Date() // 今天
        try repository.save(item2)
        
        // 不需要复习的
        let item3 = createTestItem(title: "不需复习", mastery: .mastered)
        item3.nextReviewDate = Date().addingTimeInterval(86400 * 7) // 一周后
        try repository.save(item3)
        
        let reviewItems = repository.fetchForReview()
        #expect(reviewItems.count == 2)
    }
    
    @Test("fetchHighPriority 返回高优先级错题")
    func fetchHighPriority() throws {
        let (repository, _) = try createRepository()
        
        // 逾期的高优先级
        let item1 = createTestItem(title: "逾期题", mastery: .none)
        item1.nextReviewDate = Date().addingTimeInterval(-86400 * 3) // 3天前
        try repository.save(item1)
        
        // 今天需要复习的
        let item2 = createTestItem(title: "今日题", mastery: .partial)
        item2.nextReviewDate = Date()
        try repository.save(item2)
        
        let highPriority = repository.fetchHighPriority(limit: 10)
        // 至少有逾期的应该在高优先级中
        #expect(highPriority.count >= 1)
    }
    
    @Test("fetchRecent 返回最近的错题")
    func fetchRecent() throws {
        let (repository, _) = try createRepository()
        
        for i in 1...15 {
            try repository.save(createTestItem(title: "题目\(i)"))
        }
        
        let recentItems = repository.fetchRecent(limit: 5)
        #expect(recentItems.count == 5)
    }
    
    // MARK: - 搜索测试
    
    @Test("search 按标题搜索")
    func searchByTitle() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "二次函数求最值"))
        try repository.save(createTestItem(title: "一次函数图像"))
        try repository.save(createTestItem(title: "三角形面积"))
        
        let results = repository.search(query: "函数")
        #expect(results.count == 2)
    }
    
    @Test("search 不区分大小写")
    func searchCaseInsensitive() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "DNA复制过程"))
        try repository.save(createTestItem(title: "RNA转录"))
        
        let results = repository.search(query: "dna")
        #expect(results.count == 1)
    }
    
    @Test("search 空查询返回所有")
    func searchEmptyQuery() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "题1"))
        try repository.save(createTestItem(title: "题2"))
        
        let results = repository.search(query: "")
        #expect(results.count == 2)
        
        let results2 = repository.search(query: "   ")
        #expect(results2.count == 2)
    }
    
    @Test("search 按学科名称搜索")
    func searchBySubjectName() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "题1", subject: .math))
        try repository.save(createTestItem(title: "题2", subject: .physics))
        
        let results = repository.search(query: "数学")
        #expect(results.count == 1)
    }
    
    // MARK: - 删除测试
    
    @Test("删除单个错题")
    func deleteItem() throws {
        let (repository, _) = try createRepository()
        
        let item = createTestItem()
        try repository.save(item)
        #expect(repository.fetchAll().count == 1)
        
        try repository.delete(item)
        #expect(repository.fetchAll().count == 0)
    }
    
    @Test("批量删除错题")
    func deleteMultipleItems() throws {
        let (repository, _) = try createRepository()
        
        let item1 = createTestItem(title: "题1")
        let item2 = createTestItem(title: "题2")
        let item3 = createTestItem(title: "题3")
        
        try repository.save(item1)
        try repository.save(item2)
        try repository.save(item3)
        #expect(repository.fetchAll().count == 3)
        
        try repository.delete([item1, item2])
        #expect(repository.fetchAll().count == 1)
        #expect(repository.fetchAll().first?.title == "题3")
    }
    
    @Test("删除所有错题")
    func deleteAllItems() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "题1"))
        try repository.save(createTestItem(title: "题2"))
        try repository.save(createTestItem(title: "题3"))
        #expect(repository.fetchAll().count == 3)
        
        try repository.deleteAll()
        #expect(repository.fetchAll().count == 0)
    }
    
    // MARK: - 存在性检查测试
    
    @Test("exists 正确判断")
    func existsCheck() throws {
        let (repository, _) = try createRepository()
        
        let item = createTestItem()
        try repository.save(item)
        
        #expect(repository.exists(id: item.id) == true)
        #expect(repository.exists(id: UUID()) == false)
    }
    
    // MARK: - 统计测试
    
    @Test("statistics 返回正确统计")
    func statisticsCalculation() throws {
        let (repository, _) = try createRepository()
        
        try repository.save(createTestItem(title: "数学1", subject: .math, mastery: .mastered))
        try repository.save(createTestItem(title: "数学2", subject: .math, mastery: .partial))
        try repository.save(createTestItem(title: "物理1", subject: .physics, mastery: .none))
        
        let stats = repository.statistics()
        
        #expect(stats.totalCount == 3)
        #expect(stats.masteredCount == 1)
    }
    
    @Test("空仓库统计正确")
    func emptyStatistics() throws {
        let (repository, _) = try createRepository()
        
        let stats = repository.statistics()
        
        #expect(stats.totalCount == 0)
        #expect(stats.masteredCount == 0)
    }
}
