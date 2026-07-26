//
//  ArchiveItemModelTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  ArchiveItemModel 单元测试，验证模型属性默认值与计算属性行为。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData

struct ArchiveItemModelTests {
    
    // MARK: - Helper Methods
    
    /// 提供统一的隔离测试上下文
    private func createTestContext() throws -> ModelContext {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(SnapDrillSchemaV1.models), configurations: config)
        return ModelContext(container)
    }

    // MARK: - Core Field Mapping & Default Values

    @Test("验证模型默认构造满足所有业务隐式要求")
    func initializationDefaults() {
        let model = ArchiveItemModel(content: "Empty Test")

        #expect(model.id.uuidString != "00000000-0000-0000-0000-000000000000")
        #expect(model.content == "Empty Test")
        #expect(model.easeFactor == 2.5, "SM-2 初始 ease factor 必须是 2.5")
        #expect(model.interval == 0)
        #expect(model.categoryValues?.isEmpty == true)
    }
    
    @Test("验证 toExportSnapshot 正确映射导出字段（分类经动态维度值）")
    func exportSnapshotMappingCompleteness() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(SnapDrillSchemaV1.models), configurations: config)
        let context = ModelContext(container)

        let dimension = CategoryDimensionModel(
            name: "分类", isBuiltIn: true, systemKey: CategorySystemKey.category, icon: "book"
        )
        context.insert(dimension)
        let value = CategoryValueModel(name: "数学", dimension: dimension)
        context.insert(value)

        let expectedID = UUID()
        let now = Date()
        let model = ArchiveItemModel(
            id: expectedID,
            content: "Math Formula",
            imagePath: "test/image.jpg",
            createdAt: now
        )
        context.insert(model)
        model.categoryValues = [value]
        try context.save()

        let snapshot = model.toExportSnapshot()

        #expect(snapshot.id == expectedID)
        #expect(snapshot.content == "Math Formula")
        #expect(snapshot.imagePath == "test/image.jpg")
        // category = 分类维度首值（PDF 页眉用）；CSV 动态列经 dimensionValues
        #expect(snapshot.category == "数学")
        #expect(snapshot.dimensionValues["分类"] == ["数学"])
        #expect(snapshot.createdAt == now)
    }

    @Test("toExportSnapshot：无分类值题目 exportCategory 归一 nil（PDF 页眉 compactMap 兜底契约）")
    func exportSnapshotEmptyCategoryNormalizesToNil() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(SnapDrillSchemaV1.models), configurations: config)
        let context = ModelContext(container)
        let model = ArchiveItemModel(content: "无分类题")
        context.insert(model)
        try context.save()

        let snapshot = model.toExportSnapshot()
        #expect(snapshot.category == "")
        // 空串须归一 nil，否则污染 PDFExportService.resolveCategory 的 categories 集合
        #expect(snapshot.exportCategory == nil)
        #expect(snapshot.dimensionValues.isEmpty)
    }
    
    // MARK: - Persistence Lifecycle & Constraint Checks
    
    @Test("SwiftData Context 的基本生命周期，验证插入和删除影响")
    func persistenceLifecycle() throws {
        let context = try createTestContext()
        let model = ArchiveItemModel(content: "Lifecycle Test")
        
        // 1. Insert
        context.insert(model)
        try context.save()
        
        var fetchDescriptor = FetchDescriptor<ArchiveItemModel>()
        var results = try context.fetch(fetchDescriptor)
        #expect(results.count == 1)
        #expect(results.first?.content == "Lifecycle Test")
        
        // 2. Update
        model.content = "Updated Lifecycle"
        try context.save()
        
        fetchDescriptor = FetchDescriptor<ArchiveItemModel>()
        results = try context.fetch(fetchDescriptor)
        #expect(results.first?.content == "Updated Lifecycle")
        
        // 3. Delete
        context.delete(model)
        try context.save()
        
        results = try context.fetch(FetchDescriptor<ArchiveItemModel>())
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
        
        let model = ArchiveItemModel(content: "Extreme EF", easeFactor: abnormalEaseFactor)
        context.insert(model)
        
        // 这里仅断言旧开发字段在本检查点移除前仍可安全持久化。
        try context.save()
        
        let results = try context.fetch(FetchDescriptor<ArchiveItemModel>())
        #expect(results.first?.easeFactor == abnormalEaseFactor)
    }
}
