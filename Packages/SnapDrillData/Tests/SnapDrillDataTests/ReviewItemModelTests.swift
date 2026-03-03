//
//  ReviewItemModelTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData
@testable import SnapDrillCore

@MainActor
struct ReviewItemModelTests {
    
    // MARK: - Helper Methods
    
    /// 提供统一的隔离测试上下文
    private func createTestContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: ReviewItemModel.self, TagModel.self, configurations: config)
        return ModelContext(container)
    }
    
    // MARK: - Core Field Mapping & Default Values
    
    @Test("验证模型默认构造满足所有业务隐式要求")
    func initializationDefaults() {
        let model = ReviewItemModel(content: "Empty Test")
        
        #expect(model.id.uuidString != "00000000-0000-0000-0000-000000000000")
        #expect(model.content == "Empty Test")
        #expect(model.subjectRawValue == "其他")
        #expect(model.sourceRawValue == "其他")
        #expect(model.easeFactor == 2.5, "SM-2 初始 ease factor 必须是 2.5")
        #expect(model.interval == 0)
        #expect(model.difficulty == 1, "新题默认难度为 1 星（Difficulty.one.rawValue）")
        #expect(model.tags?.isEmpty == true)
    }
    
    @Test("验证 toExportSnapshot 正确映射导出所需的六个字段")
    func exportSnapshotMappingCompleteness() {
        let expectedID = UUID()
        let now = Date()

        let model = ReviewItemModel(
            id: expectedID,
            content: "Math Formula",
            imagePath: "test/image.jpg",
            createdAt: now,
            subject: "数学",
            source: "试卷"
        )

        let snapshot = model.toExportSnapshot()

        #expect(snapshot.id == expectedID)
        #expect(snapshot.content == "Math Formula")
        #expect(snapshot.imagePath == "test/image.jpg")
        #expect(snapshot.subject == "数学")
        #expect(snapshot.source == "试卷")
        #expect(snapshot.createdAt == now)
    }
    
    // MARK: - Persistence Lifecycle & Constraint Checks
    
    @Test("SwiftData Context 的基本生命周期，验证插入和删除影响")
    func persistenceLifecycle() throws {
        let context = try createTestContext()
        let model = ReviewItemModel(content: "Lifecycle Test")
        
        // 1. Insert
        context.insert(model)
        try context.save()
        
        var fetchDescriptor = FetchDescriptor<ReviewItemModel>()
        var results = try context.fetch(fetchDescriptor)
        #expect(results.count == 1)
        #expect(results.first?.content == "Lifecycle Test")
        
        // 2. Update
        model.content = "Updated Lifecycle"
        model.difficulty = 5
        try context.save()
        
        fetchDescriptor = FetchDescriptor<ReviewItemModel>()
        results = try context.fetch(fetchDescriptor)
        #expect(results.first?.content == "Updated Lifecycle")
        #expect(results.first?.difficulty == 5)
        
        // 3. Delete
        context.delete(model)
        try context.save()
        
        results = try context.fetch(FetchDescriptor<ReviewItemModel>())
        #expect(results.isEmpty)
    }
    
    // MARK: - Boundary Conditions
    
    @Test(
        "模型能安全承载超出预期的极大或极小状态系（防崩溃校验）",
        arguments: [
            (-999.9),   // 突破最低 EF
            (100.0),    // 过高的 EF
            (0.0)       // 零处理
        ]
    )
    func easeFactorBoundaryTolerance(abnormalEaseFactor: Double) throws {
        let context = try createTestContext()
        
        let model = ReviewItemModel(content: "Extreme EF", easeFactor: abnormalEaseFactor)
        context.insert(model)
        
        // 这里仅断言 Model 层作为简单的 ORM 能够成功储存在数据库即可，
        // 调度算法自身的边界拦截由 `ReviewSchedulerTests` 负责，此处不应崩溃。
        try context.save()
        
        let results = try context.fetch(FetchDescriptor<ReviewItemModel>())
        #expect(results.first?.easeFactor == abnormalEaseFactor)
    }
}
