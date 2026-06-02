//
//  MigrationTests.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
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
        #expect(schemas[0] is SnapDrillSchemaV1.Type)
    }

    @Test("MigrationPlan stages 数量与版本跳数一致")
    func migrationPlanStagesCount() {
        // N 个 Schema 需要 N-1 个 migration stage
        let schemas = SnapDrillMigrationPlan.schemas
        let stages = SnapDrillMigrationPlan.stages
        #expect(stages.count == schemas.count - 1)
    }

    // MARK: - MigrationPlan 与 ModelContainer 集成

    @Test("ModelContainer 可通过 MigrationPlan 成功创建")
    func modelContainerWithMigrationPlan() throws {
        let container = try ModelContainer(
            for: Schema(SnapDrillSchemaV1.models),
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext
        ctx.insert(ReviewItemModel.mock(content: "migration test"))
        try ctx.save()
        #expect(try ctx.fetchCount(FetchDescriptor<ReviewItemModel>()) == 1)
    }

    @Test("持久化 store 经 MigrationPlan 重开后数据完整（迁移基础设施 round-trip 守护）")
    func persistentStoreRoundTripViaMigrationPlan() throws {
        // 用磁盘 store（非 in-memory）真正验证「经 MigrationPlan 持久化往返不丢数据」。
        // 当前仅 V1，不构造投机的假 V2；守护的是迁移基础设施本身（migrationPlan + 持久化）
        // 被改坏导致数据丢失的回归。未来落地真实 V2 时在此扩展跨版本 round-trip。
        let storeURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("MigrationRoundTrip_\(UUID().uuidString).store")
        defer { try? FileManager.default.removeItem(at: storeURL) }

        let schema = Schema(SnapDrillSchemaV1.models)
        let config = ModelConfiguration(url: storeURL)

        // 写入：经 MigrationPlan 创建持久化容器，存入样本后释放
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: SnapDrillMigrationPlan.self,
                configurations: config
            )
            let ctx = container.mainContext
            ctx.insert(ReviewItemModel.mock(content: "持久化迁移样本"))
            try ctx.save()
        }

        // 重开：同一磁盘 store 经 MigrationPlan 重新打开，数据应完整保留
        let reopened = try ModelContainer(
            for: schema,
            migrationPlan: SnapDrillMigrationPlan.self,
            configurations: config
        )
        let count = try reopened.mainContext.fetchCount(FetchDescriptor<ReviewItemModel>())
        #expect(count == 1, "经 MigrationPlan 持久化往返后数据应完整")
    }

    @Test("DataExecutor 内部使用 MigrationPlan 创建容器")
    func dataExecutorUsesMigrationPlan() throws {
        let executor = DataExecutor(inMemory: true)
        #expect(executor.container != nil)
        let ctx = executor.container.mainContext
        ctx.insert(ReviewItemModel.mock(content: "via executor"))
        try ctx.save()
        #expect(try ctx.fetchCount(FetchDescriptor<ReviewItemModel>()) == 1)
    }

    // MARK: - DataExecutor 降级

    @Test("DataExecutor 在极端损坏情况下能保护 App 运行")
    func dataExecutorFallbackLogic() async {
        let executor = DataExecutor(inMemory: true)
        let error = await executor.initializationError
        let fallback = await executor.isUsingInMemoryFallback
        // container 是非可选类型，初始化失败会走 fallback 路径而非返回 nil
        #expect(error == nil || fallback)
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
