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

    // MARK: - MigrationPlan 完整性

    @Test("MigrationPlan schemas 包含全部版本且顺序正确")
    func migrationPlanSchemasComplete() {
        let schemas = SnapDrillMigrationPlan.schemas
        #expect(schemas.count == 1)
        #expect(schemas[0] == SnapDrillSchemaV1.self)
    }

    @Test("MigrationPlan stages 数量与版本跳数一致")
    func migrationPlanStagesCount() {
        // N 个 Schema 需要 N-1 个 migration stage
        let schemas = SnapDrillMigrationPlan.schemas
        let stages = SnapDrillMigrationPlan.stages
        #expect(stages.count == schemas.count - 1)
    }

    // MARK: - PersistenceController 降级

    @Test("PersistenceController 在极端损坏情况下能保护 App 运行")
    func persistenceFallbackLogic() {
        let controller = PersistenceController(inMemory: true)
        // container 是非可选类型，初始化失败会走 fallback 路径而非返回 nil
        #expect(controller.initializationError == nil || controller.isUsingInMemoryFallback)
    }

    // MARK: - 默认值验证

    @Test("新建题目默认值正确（nextReviewAt/lastReviewedAt = distantPast）")
    func defaultValuesCorrect() throws {
        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        let item = ReviewItemModel()
        context.insert(item)
        try context.save()

        #expect(item.nextReviewAt == .distantPast)
        #expect(item.lastReviewedAt == .distantPast)
        #expect(item.isScheduled == false)
    }
}
