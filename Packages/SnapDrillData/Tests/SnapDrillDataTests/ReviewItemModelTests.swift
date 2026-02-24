//
//  ReviewItemModelTests.swift
//  SnapDrillDataTests
//
//  Created by SnapDrill Labs on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  ReviewItemModel 单元测试
//

import XCTest
import SwiftData
@testable import SnapDrillData
@testable import SnapDrillCore

@MainActor
final class ReviewItemModelTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存数据库用于测试
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: ReviewItemModel.self,
            configurations: config
        )
        context = ModelContext(container)
    }
    
    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    /// 测试：使用有效数据应该创建模型
    func testInit_WithValidData_ShouldCreateModel() {
        // Arrange & Act
        let model = ReviewItemModel(
            content: "Test question",
            subject: "数学",
            source: "作业"
        )
        
        // Assert
        XCTAssertNotNil(model.id)
        XCTAssertEqual(model.content, "Test question")
        XCTAssertEqual(model.subject, "数学")
        XCTAssertEqual(model.source, "作业")
        XCTAssertNotNil(model.createdAt)
    }
    
    /// 测试：使用默认值应该使用正确的默认值
    func testInit_WithDefaultValues_ShouldUseDefaults() {
        // Arrange & Act
        let model = ReviewItemModel(content: "Test")
        
        // Assert
        XCTAssertEqual(model.subject, "其他")
        XCTAssertEqual(model.source, "其他")
        XCTAssertEqual(model.easeFactor, 2.5)
        XCTAssertEqual(model.interval, 0)
        XCTAssertEqual(model.repetitions, 0)
        XCTAssertEqual(model.difficulty, 0)
    }
    
    /// 测试：CloudKit 兼容性 - 所有必需字段都有默认值
    func testCloudKitCompatibility_AllRequiredFieldsHaveDefaults() {
        // Arrange & Act
        let model = ReviewItemModel(content: "")
        
        // Assert - 所有非可选字段都应该有默认值
        XCTAssertNotNil(model.id)
        XCTAssertNotNil(model.content)
        XCTAssertNotNil(model.createdAt)
        XCTAssertNotNil(model.subjectRawValue)
        XCTAssertNotNil(model.sourceRawValue)
    }
    
    // MARK: - Property Tests
    
    /// 测试：subject 属性应该正确获取和设置
    func testSubjectProperty_ShouldGetAndSetCorrectly() {
        // Arrange
        let model = ReviewItemModel(content: "Test")
        
        // Act
        model.subject = "英语"
        
        // Assert
        XCTAssertEqual(model.subject, "英语")
        XCTAssertEqual(model.subjectRawValue, "英语")
    }
    
    /// 测试：source 属性应该正确获取和设置
    func testSourceProperty_ShouldGetAndSetCorrectly() {
        // Arrange
        let model = ReviewItemModel(content: "Test")
        
        // Act
        model.source = "试卷"
        
        // Assert
        XCTAssertEqual(model.source, "试卷")
        XCTAssertEqual(model.sourceRawValue, "试卷")
    }
    
    // MARK: - toEntity Tests
    
    /// 测试：toEntity 应该正确转换为 ReviewItem
    func testToEntity_ShouldConvertCorrectly() {
        // Arrange
        let model = ReviewItemModel(
            id: UUID(),
            content: "Test content",
            imagePath: "test.jpg",
            subject: "数学",
            source: "作业",
            answerText: "Answer",
            difficulty: 3,
            easeFactor: 2.6,
            interval: 7,
            repetitions: 2
        )
        
        // Act
        let entity = model.toEntity()
        
        // Assert
        XCTAssertEqual(entity.id, model.id)
        XCTAssertEqual(entity.content, model.content)
        XCTAssertEqual(entity.imagePath, model.imagePath)
        XCTAssertEqual(entity.subject, model.subject)
        XCTAssertEqual(entity.source, model.source)
        XCTAssertEqual(entity.answerText, model.answerText)
        XCTAssertEqual(entity.difficulty, model.difficulty)
        XCTAssertEqual(entity.easeFactor, model.easeFactor)
        XCTAssertEqual(entity.interval, model.interval)
        XCTAssertEqual(entity.repetitions, model.repetitions)
    }
    
    // MARK: - Persistence Tests
    
    /// 测试：应该能够保存到 ModelContext
    func testSave_ShouldPersistToContext() throws {
        // Arrange
        let model = ReviewItemModel(content: "Test")
        
        // Act
        context.insert(model)
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<ReviewItemModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Test")
    }
    
    /// 测试：应该能够更新已保存的模型
    func testUpdate_ShouldModifyPersistedModel() throws {
        // Arrange
        let model = ReviewItemModel(content: "Original")
        context.insert(model)
        try context.save()
        
        // Act
        model.content = "Updated"
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<ReviewItemModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.first?.content, "Updated")
    }
    
    /// 测试：应该能够删除模型
    func testDelete_ShouldRemoveFromContext() throws {
        // Arrange
        let model = ReviewItemModel(content: "Test")
        context.insert(model)
        try context.save()
        
        // Act
        context.delete(model)
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<ReviewItemModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 0)
    }
    
    /// 测试：应该能够查询特定条件的模型
    func testFetch_WithPredicate_ShouldReturnMatchingItems() throws {
        // Arrange
        let model1 = ReviewItemModel(content: "Math", subject: "数学")
        let model2 = ReviewItemModel(content: "English", subject: "英语")
        context.insert(model1)
        context.insert(model2)
        try context.save()
        
        // Act
        let predicate = #Predicate<ReviewItemModel> { $0.subjectRawValue == "数学" }
        var fetchDescriptor = FetchDescriptor<ReviewItemModel>(predicate: predicate)
        let results = try context.fetch(fetchDescriptor)
        
        // Assert
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.content, "Math")
    }
}
