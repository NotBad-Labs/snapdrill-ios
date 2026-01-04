//
//  PersistenceControllerTests.swift
//  NotBadDataTests
//
//  Created by NotBad Architect on 2026/01/02.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  PersistenceController 单元测试
//

import XCTest
import SwiftData
@testable import NotBadData

@MainActor
final class PersistenceControllerTests: XCTestCase {
    
    func testInitializeWithInMemory() throws {
        // When
        let controller = PersistenceController(inMemory: true)
        
        // Then
        XCTAssertNotNil(controller.container)
        XCTAssertFalse(controller.isUsingInMemoryFallback)
        XCTAssertNil(controller.initializationError)
    }
    
    func testContainerIsAccessible() throws {
        // Given
        let controller = PersistenceController(inMemory: true)
        
        // When
        let context = controller.container.mainContext
        
        // Then
        XCTAssertNotNil(context)
    }
    
    func testCanInsertAndFetchData() throws {
        // Given
        let controller = PersistenceController(inMemory: true)
        let context = controller.container.mainContext
        
        // When
        let model = ReviewItemModel(
            id: UUID(),
            content: "测试题目",
            subject: "数学",
            source: "试卷"
        )
        context.insert(model)
        try context.save()
        
        // Then
        let descriptor = FetchDescriptor<ReviewItemModel>()
        let items = try context.fetch(descriptor)
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.content, "测试题目")
    }
    
    func testSharedInstanceIsAccessible() {
        // When
        let shared = PersistenceController.shared
        
        // Then
        XCTAssertNotNil(shared.container)
    }
    
    func testFallbackFlagInitiallyFalse() {
        // Given
        let controller = PersistenceController(inMemory: true)
        
        // Then
        XCTAssertFalse(controller.isUsingInMemoryFallback)
    }
    
    func testErrorPropertyInitiallyNil() {
        // Given
        let controller = PersistenceController(inMemory: true)
        
        // Then
        XCTAssertNil(controller.initializationError)
    }
}
