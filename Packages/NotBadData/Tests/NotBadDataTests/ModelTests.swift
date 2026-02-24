//
//  ModelTests.swift
//  NotBadDataTests
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SubjectModel, SourceModel, TagModel 单元测试
//

import XCTest
import SwiftData
@testable import NotBadData

@MainActor
final class ModelTests: XCTestCase {
    
    var container: ModelContainer!
    var context: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(
            for: SubjectModel.self, SourceModel.self, TagModel.self,
            configurations: config
        )
        context = ModelContext(container)
    }
    
    override func tearDown() async throws {
        context = nil
        container = nil
        try await super.tearDown()
    }
    
    // MARK: - SubjectModel Tests
    
    func testSubjectModel_Init_WithValidData_ShouldCreateModel() {
        // Arrange & Act
        let model = SubjectModel(
            name: "数学",
            icon: "function",
            colorHex: "#FF0000",
            sortOrder: 1
        )
        
        // Assert
        XCTAssertNotNil(model.id)
        XCTAssertEqual(model.name, "数学")
        XCTAssertEqual(model.icon, "function")
        XCTAssertEqual(model.colorHex, "#FF0000")
        XCTAssertEqual(model.sortOrder, 1)
    }
    
    func testSubjectModel_DefaultValues_ShouldBeCorrect() {
        // Arrange & Act
        let model = SubjectModel(name: "", icon: "", colorHex: "", sortOrder: 0)
        
        // Assert - CloudKit 兼容性：所有字段都有默认值
        XCTAssertNotNil(model.id)
        XCTAssertEqual(model.name, "")
        XCTAssertEqual(model.icon, "")
        XCTAssertEqual(model.colorHex, "")
        XCTAssertEqual(model.sortOrder, 0)
    }
    
    func testSubjectModel_Persistence_ShouldSaveAndFetch() throws {
        // Arrange
        let model = SubjectModel(name: "英语", icon: "book", colorHex: "#00FF00", sortOrder: 2)
        
        // Act
        context.insert(model)
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<SubjectModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "英语")
    }
    
    // MARK: - SourceModel Tests
    
    func testSourceModel_Init_WithValidData_ShouldCreateModel() {
        // Arrange & Act
        let model = SourceModel(
            name: "作业",
            icon: "doc.text",
            colorHex: "#0000FF",
            sortOrder: 1
        )
        
        // Assert
        XCTAssertEqual(model.name, "作业")
        XCTAssertEqual(model.icon, "doc.text")
        XCTAssertEqual(model.colorHex, "#0000FF")
        XCTAssertEqual(model.sortOrder, 1)
    }
    
    func testSourceModel_DefaultValues_ShouldBeCorrect() {
        // Arrange & Act
        let model = SourceModel(name: "")
        
        // Assert - CloudKit 兼容性
        XCTAssertEqual(model.name, "")
        XCTAssertEqual(model.icon, "doc.text") // 默认值
        XCTAssertEqual(model.colorHex, "#808080") // 默认值
        XCTAssertEqual(model.sortOrder, 0) // 默认值
    }
    
    func testSourceModel_Persistence_ShouldSaveAndFetch() throws {
        // Arrange
        let model = SourceModel(name: "试卷", icon: "doc", colorHex: "#FFFF00", sortOrder: 3)
        
        // Act
        context.insert(model)
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<SourceModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "试卷")
    }
    
    // MARK: - TagModel Tests
    
    func testTagModel_Init_WithValidData_ShouldCreateModel() {
        // Arrange & Act
        let model = TagModel(
            name: "粗心",
            colorHex: "#FF00FF"
        )
        
        // Assert
        XCTAssertNotNil(model.id)
        XCTAssertEqual(model.name, "粗心")
        XCTAssertEqual(model.colorHex, "#FF00FF")
        XCTAssertNotNil(model.createdAt)
    }
    
    func testTagModel_DefaultValues_ShouldBeCorrect() {
        // Arrange & Act
        let model = TagModel(name: "")
        
        // Assert - CloudKit 兼容性
        XCTAssertNotNil(model.id)
        XCTAssertEqual(model.name, "")
        XCTAssertEqual(model.colorHex, "#8E8E93") // 默认值
        XCTAssertNotNil(model.createdAt)
    }
    
    func testTagModel_Persistence_ShouldSaveAndFetch() throws {
        // Arrange
        let model = TagModel(name: "计算错误", colorHex: "#00FFFF")
        
        // Act
        context.insert(model)
        try context.save()
        
        // Assert
        let fetchDescriptor = FetchDescriptor<TagModel>()
        let results = try context.fetch(fetchDescriptor)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.name, "计算错误")
    }
    
    func testTagModel_Relationship_ShouldHandleItems() throws {
        // Arrange
        let tag = TagModel(name: "重点")
        context.insert(tag)
        
        // Act & Assert
        XCTAssertNotNil(tag.items)
        XCTAssertEqual(tag.items?.count ?? 0, 0)
    }
    
    // MARK: - Sorting Tests
    
    func testSubjectModel_Sorting_BySortOrder_ShouldWork() throws {
        // Arrange
        let subject1 = SubjectModel(name: "数学", icon: "a", colorHex: "#000", sortOrder: 2)
        let subject2 = SubjectModel(name: "英语", icon: "b", colorHex: "#000", sortOrder: 1)
        let subject3 = SubjectModel(name: "物理", icon: "c", colorHex: "#000", sortOrder: 3)
        
        context.insert(subject1)
        context.insert(subject2)
        context.insert(subject3)
        try context.save()
        
        // Act
        var fetchDescriptor = FetchDescriptor<SubjectModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let results = try context.fetch(fetchDescriptor)
        
        // Assert
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].name, "英语") // sortOrder 1
        XCTAssertEqual(results[1].name, "数学") // sortOrder 2
        XCTAssertEqual(results[2].name, "物理") // sortOrder 3
    }
    
    func testSourceModel_Sorting_BySortOrder_ShouldWork() throws {
        // Arrange
        let source1 = SourceModel(name: "作业", sortOrder: 3)
        let source2 = SourceModel(name: "试卷", sortOrder: 1)
        let source3 = SourceModel(name: "教材", sortOrder: 2)
        
        context.insert(source1)
        context.insert(source2)
        context.insert(source3)
        try context.save()
        
        // Act
        var fetchDescriptor = FetchDescriptor<SourceModel>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        let results = try context.fetch(fetchDescriptor)
        
        // Assert
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].name, "试卷")
        XCTAssertEqual(results[1].name, "教材")
        XCTAssertEqual(results[2].name, "作业")
    }
}
