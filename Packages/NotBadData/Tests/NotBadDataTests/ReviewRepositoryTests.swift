//
//  ReviewRepositoryTests.swift
//  NotBadDataTests
//
//  Created by NotBad Architect on 2026/01/02.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  ReviewRepository 单元测试
//

import XCTest
import SwiftData
@testable import NotBadData
@testable import NotBadCore

@MainActor
final class ReviewRepositoryTests: XCTestCase {
    var modelContainer: ModelContainer?
    var modelContext: ModelContext?
    var repository: ReviewRepository?
    
    override func setUp() async throws {
        // 使用内存存储创建测试容器
        let schema = Schema([ReviewItemModel.self, TagModel.self, SubjectModel.self, SourceModel.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        repository = ReviewRepository(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        repository = nil
    }
    
    // MARK: - Save Tests
    
    func testSaveNewItem() throws {
        // Given
        let item = ReviewItem(
            id: UUID(),
            content: "测试题目",
            imagePath: nil,
            createdAt: Date(),
            lastReviewedAt: nil,
            nextReviewAt: nil,
            subject: "数学",
            source: "试卷",
            tags: [],
            answerText: "测试答案",
            answerImagePath: nil,
            difficulty: 3,
            grade: "高一"
        )
        
        // When
        try repository.save(item)
        
        // Then
        let fetchedItems = try repository.fetchAll()
        XCTAssertEqual(fetchedItems.count, 1)
        XCTAssertEqual(fetchedItems.first?.content, "测试题目")
        XCTAssertEqual(fetchedItems.first?.difficulty, 3)
    }
    
    func testSaveDuplicateItemThrowsError() throws {
        // Given
        let id = UUID()
        let item1 = ReviewItem(id: id, content: "题目1", subject: "数学", source: "试卷")
        let item2 = ReviewItem(id: id, content: "题目2", subject: "英语", source: "作业")
        
        // When
        try repository.save(item1)
        
        // Then
        XCTAssertThrowsError(try repository.save(item2)) { error in
            guard case DataError.duplicateItem(let duplicateId) = error else {
                XCTFail("Expected DataError.duplicateItem, got \(error)")
                return
            }
            XCTAssertEqual(duplicateId, id)
        }
    }
    
    // MARK: - Fetch Tests
    
    func testFetchAll() throws {
        // Given
        let items = [
            ReviewItem(id: UUID(), content: "题目1", subject: "数学", source: "试卷"),
            ReviewItem(id: UUID(), content: "题目2", subject: "英语", source: "作业"),
            ReviewItem(id: UUID(), content: "题目3", subject: "物理", source: "教材")
        ]
        
        for item in items {
            try repository.save(item)
        }
        
        // When
        let fetchedItems = try repository.fetchAll()
        
        // Then
        XCTAssertEqual(fetchedItems.count, 3)
        // 应该按创建时间倒序排列
        XCTAssertEqual(fetchedItems.last?.content, "题目1")
    }
    
    func testFetchById() throws {
        // Given
        let id = UUID()
        let item = ReviewItem(id: id, content: "测试题目", subject: "数学", source: "试卷")
        try repository.save(item)
        
        // When
        let fetchedItem = try repository.fetchById(id)
        
        // Then
        XCTAssertNotNil(fetchedItem)
        XCTAssertEqual(fetchedItem?.id, id)
        XCTAssertEqual(fetchedItem?.content, "测试题目")
    }
    
    func testFetchByIdNotFound() throws {
        // Given
        let nonExistentId = UUID()
        
        // When
        let fetchedItem = try repository.fetchById(nonExistentId)
        
        // Then
        XCTAssertNil(fetchedItem)
    }
    
    func testFetchDueCount() throws {
        // Given
        let now = Date()
        let past = now.addingTimeInterval(-3600) // 1小时前
        let future = now.addingTimeInterval(3600) // 1小时后
        
        let items = [
            ReviewItem(id: UUID(), content: "已到期1", nextReviewAt: past, subject: "数学", source: "试卷"),
            ReviewItem(id: UUID(), content: "已到期2", nextReviewAt: past, subject: "英语", source: "作业"),
            ReviewItem(id: UUID(), content: "未到期", nextReviewAt: future, subject: "物理", source: "教材"),
            ReviewItem(id: UUID(), content: "无复习时间", nextReviewAt: nil, subject: "化学", source: "试卷")
        ]
        
        for item in items {
            try repository.save(item)
        }
        
        // When
        let dueCount = try repository.fetchDueCount()
        
        // Then
        XCTAssertEqual(dueCount, 2)
    }
    
    func testTotalItemCount() throws {
        // Given
        let items = [
            ReviewItem(id: UUID(), content: "题目1", subject: "数学", source: "试卷"),
            ReviewItem(id: UUID(), content: "题目2", subject: "英语", source: "作业")
        ]
        
        for item in items {
            try repository.save(item)
        }
        
        // When
        let count = try repository.totalItemCount()
        
        // Then
        XCTAssertEqual(count, 2)
    }
    
    // MARK: - Update Tests
    
    func testUpdateExistingItem() throws {
        // Given
        let id = UUID()
        let originalItem = ReviewItem(id: id, content: "原始内容", difficulty: 1, subject: "数学", source: "试卷")
        try repository.save(originalItem)
        
        // When
        let updatedItem = ReviewItem(
            id: id,
            content: "更新内容",
            difficulty: 5,
            subject: "数学",
            source: "试卷"
        )
        try repository.update(updatedItem)
        
        // Then
        let fetchedItem = try repository.fetchById(id)
        XCTAssertEqual(fetchedItem?.content, "更新内容")
        XCTAssertEqual(fetchedItem?.difficulty, 5)
    }
    
    func testUpdateNonExistentItemThrowsError() throws {
        // Given
        let nonExistentId = UUID()
        let item = ReviewItem(id: nonExistentId, content: "不存在的题目", subject: "数学", source: "试卷")
        
        // When & Then
        XCTAssertThrowsError(try repository.update(item)) { error in
            guard case DataError.notFound(let id, let entityType) = error else {
                XCTFail("Expected DataError.notFound, got \(error)")
                return
            }
            XCTAssertEqual(id, nonExistentId)
            XCTAssertEqual(entityType, "ReviewItem")
        }
    }
    
    // MARK: - Delete Tests
    
    func testDeleteItem() throws {
        // Given
        let item = ReviewItem(id: UUID(), content: "待删除题目", subject: "数学", source: "试卷")
        try repository.save(item)
        let fetchedItem = try repository?.fetchById(item.id)
        guard let fetchedItem = fetchedItem else {
            XCTFail("Failed to fetch item")
            return
        }
        
        // When
        repository?.delete(fetchedItem)
        try repository?.save()
        
        // Then
        let afterDelete = try repository.fetchById(item.id)
        XCTAssertNil(afterDelete)
        XCTAssertEqual(try repository.totalItemCount(), 0)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() throws {
        // 1. 创建
        let id = UUID()
        let item = ReviewItem(id: id, content: "完整流程测试", difficulty: 2, subject: "数学", source: "试卷")
        try repository.save(item)
        
        // 2. 读取
        var fetchedItem = try repository.fetchById(id)
        XCTAssertNotNil(fetchedItem)
        XCTAssertEqual(fetchedItem?.difficulty, 2)
        
        // 3. 更新
        let updatedItem = ReviewItem(id: id, content: "完整流程测试", difficulty: 4, subject: "数学", source: "试卷")
        try repository.update(updatedItem)
        fetchedItem = try repository?.fetchById(id)
        guard let item = fetchedItem else {
            XCTFail("Failed to fetch item")
            return
        }
        XCTAssertEqual(item.difficulty, 4)
        
        // 4. 删除
        repository?.delete(item)
        try repository?.save()
        fetchedItem = try repository?.fetchById(id)
        XCTAssertNil(fetchedItem)
    }
}
