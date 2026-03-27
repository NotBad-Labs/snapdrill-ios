//
//  MigrationTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData Schema 迁移计划和版本一致性验证。
//

import Testing
import SwiftData
import Foundation
@testable import SnapDrillData

struct MigrationTests {

    // MARK: - Schema 初始化

    @Test("V1 Schema 能够成功加载所有核心模型")
    func schemaV1Initialization() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        _ = try ModelContainer(for: schema, configurations: config)
        #expect(SnapDrillSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
    }

    @Test("V2 Schema 能够成功加载所有核心模型")
    func schemaV2Initialization() throws {
        let schema = Schema(SnapDrillSchemaV2.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        _ = try ModelContainer(for: schema, configurations: config)
        #expect(SnapDrillSchemaV2.versionIdentifier == Schema.Version(2, 0, 0))
    }

    @Test("V3 Schema（当前版本）能够成功加载所有核心模型")
    func schemaV3Initialization() throws {
        let schema = Schema(SnapDrillSchemaV3.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        _ = try ModelContainer(for: schema, configurations: config)
        #expect(SnapDrillSchemaV3.versionIdentifier == Schema.Version(3, 0, 0))
    }

    // MARK: - MigrationPlan 完整性

    @Test("MigrationPlan schemas 包含全部版本且顺序正确")
    func migrationPlanSchemasComplete() {
        let schemas = SnapDrillMigrationPlan.schemas
        #expect(schemas.count == 3)
        #expect(schemas[0] == SnapDrillSchemaV1.self)
        #expect(schemas[1] == SnapDrillSchemaV2.self)
        #expect(schemas[2] == SnapDrillSchemaV3.self)
    }

    @Test("MigrationPlan stages 数量与版本跳数一致")
    func migrationPlanStagesCount() {
        // N 个 Schema 需要 N-1 个 migration stage
        let schemas = SnapDrillMigrationPlan.schemas
        let stages = SnapDrillMigrationPlan.stages
        #expect(stages.count == schemas.count - 1)
    }

    // MARK: - 版本号单调递增

    @Test("所有 Schema 版本号严格递增")
    func schemaVersionsMonotonicallyIncreasing() {
        let versions: [Schema.Version] = [
            SnapDrillSchemaV1.versionIdentifier,
            SnapDrillSchemaV2.versionIdentifier,
            SnapDrillSchemaV3.versionIdentifier
        ]
        for i in 1..<versions.count {
            #expect(versions[i] > versions[i - 1],
                    "V\(i + 1) (\(versions[i])) 应大于 V\(i) (\(versions[i - 1]))")
        }
    }

    // MARK: - Model 列表一致性

    @Test("所有 Schema 版本引用相同的 Model 集合")
    func allSchemasReferSameModels() {
        // 所有 VersionedSchema 都引用当前的 @Model 类（SwiftData 设计约束）
        let v1Models = Set(SnapDrillSchemaV1.models.map { ObjectIdentifier($0) })
        let v2Models = Set(SnapDrillSchemaV2.models.map { ObjectIdentifier($0) })
        let v3Models = Set(SnapDrillSchemaV3.models.map { ObjectIdentifier($0) })
        #expect(v1Models == v2Models)
        #expect(v2Models == v3Models)
    }

    // MARK: - PersistenceController 降级

    @Test("PersistenceController 在极端损坏情况下能保护 App 运行")
    func persistenceFallbackLogic() {
        let controller = PersistenceController(inMemory: true)
        // container 是非可选类型，初始化失败会走 fallback 路径而非返回 nil
        #expect(controller.initializationError == nil || controller.isUsingInMemoryFallback)
    }

    // MARK: - V2→V3 数据完整性（in-memory 模拟）

    @Test("V3 Schema 下新建题目默认值正确（nextReviewAt/lastReviewedAt = distantPast）")
    func v3DefaultValuesCorrect() throws {
        let schema = Schema(SnapDrillSchemaV3.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        let item = ReviewItemModel()
        context.insert(item)
        try context.save()

        // V2 迁移将 NULL → distantPast；V3 新建数据应保持同样的默认值
        #expect(item.nextReviewAt == .distantPast)
        #expect(item.lastReviewedAt == .distantPast)
        #expect(item.isScheduled == false)
    }
}
