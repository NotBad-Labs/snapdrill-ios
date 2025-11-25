//
//  ReviewItemMigrationPlan.swift
//  NotBad
//
//  SwiftData 数据迁移计划
//

import SwiftData
import Foundation

/// ReviewItem 数据迁移计划
///
/// 负责管理不同版本之间的数据迁移，确保用户升级时数据不丢失
enum ReviewItemMigrationPlan: SchemaMigrationPlan {
    
    /// 所有版本的 Schema
    static var schemas: [VersionedSchema.Type] {
        [
            ReviewItemSchemaV1.self
            // 未来版本在此添加：ReviewItemSchemaV2.self, ReviewItemSchemaV3.self
        ]
    }
    
    /// 迁移阶段
    static var stages: [MigrationStage] {
        [
            // 未来添加迁移逻辑：migrateV1toV2
        ]
    }
    
    // MARK: - 迁移示例（未来使用）
    
    /*
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ReviewItemSchemaV1.self,
        toVersion: ReviewItemSchemaV2.self,
        willMigrate: { context in
            print("📦 开始从 V1 迁移到 V2...")
        },
        didMigrate: { context in
            print("✅ 数据迁移完成")
        }
    )
    */
}

// MARK: - Schema V1 (当前版本)

/// ReviewItem Schema V1
///
/// 初始版本的数据模型
enum ReviewItemSchemaV1: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [ReviewItem.self]
    }
}

// MARK: - 未来版本示例

/*
/// ReviewItem Schema V2
///
/// 第二版本：添加新字段或修改现有字段
enum ReviewItemSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [ReviewItem.self]
    }
}
*/
