//
//  ReviewItemMigrationPlan.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftData
import Foundation
import OSLog

// MARK: - ReviewItemMigrationPlan

/// ReviewItem 数据迁移计划
///
/// 负责管理不同版本之间的 SwiftData 数据迁移，确保用户升级时数据不丢失。
///
/// ## 迁移策略
///
/// SwiftData 提供三种迁移类型：
/// - **轻量级迁移**：自动处理简单的模型变更（添加可选字段、重命名等）
/// - **自定义迁移**：需要手动编写迁移逻辑（复杂的数据转换）
/// - **阶段迁移**：将复杂迁移拆分为多个阶段
///
/// ## 版本历史
///
/// | 版本 | 说明 | 日期 |
/// |------|------|------|
/// | V1 (1.0.0) | 初始版本 | 2025-11 |
///
/// ## 添加新版本的步骤
///
/// 1. 创建新的 `VersionedSchema` 枚举（如 `ReviewItemSchemaV2`）
/// 2. 更新 `schemas` 数组，添加新版本
/// 3. 创建 `MigrationStage`，定义迁移逻辑
/// 4. 将迁移阶段添加到 `stages` 数组
///
/// ## 使用示例
///
/// ```swift
/// // 在 App 入口配置 ModelContainer
/// let container = try ModelContainer(
///     for: ReviewItemModel.self,
///     migrationPlan: ReviewItemMigrationPlan.self
/// )
/// ```
///
/// - Note: 迁移计划在 App 启动时自动执行
/// - Important: 测试迁移时请使用测试数据，避免损坏生产数据
enum ReviewItemMigrationPlan: SchemaMigrationPlan {

    // MARK: - Schema Versions

    /// 所有版本的 Schema
    ///
    /// 按版本顺序排列，从旧到新。
    /// SwiftData 会根据此数组确定迁移路径。
    static var schemas: [VersionedSchema.Type] {
        [
            ReviewItemSchemaV1.self
            // 未来版本在此添加：
            // ReviewItemSchemaV2.self,
            // ReviewItemSchemaV3.self
        ]
    }

    // MARK: - Migration Stages

    /// 迁移阶段
    ///
    /// 定义版本之间的迁移逻辑。
    /// 空数组表示所有迁移都是轻量级迁移。
    static var stages: [MigrationStage] {
        [
            // 未来添加迁移逻辑：
            // migrateV1toV2
        ]
    }
}

// MARK: - ReviewItemMigrationPlan Future Migrations

extension ReviewItemMigrationPlan {

    // MARK: - Migration Templates

    /*
    /// V1 到 V2 的迁移
    ///
    /// 示例：添加新字段、修改数据格式
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: ReviewItemSchemaV1.self,
        toVersion: ReviewItemSchemaV2.self,
        willMigrate: { context in
            // 迁移前的准备工作
            Logger.data.info("📦 准备从 V1 迁移到 V2...")
            
            // 可以在这里备份数据或进行预处理
        },
        didMigrate: { context in
            // 迁移后的清理工作
            Logger.data.info("✅ V1 → V2 迁移完成")
            
            // 可以在这里进行数据验证或后处理
            // 例如：设置新字段的默认值
        }
    )
    */

    /*
    /// V2 到 V3 的轻量级迁移
    ///
    /// 轻量级迁移不需要自定义逻辑
    static let migrateV2toV3 = MigrationStage.lightweight(
        fromVersion: ReviewItemSchemaV2.self,
        toVersion: ReviewItemSchemaV3.self
    )
    */
}

// MARK: - ReviewItemSchemaV1

/// ReviewItem Schema V1
///
/// 初始版本的数据模型定义。
///
/// ## 包含的模型
///
/// - `ReviewItemModel`：错题持久化模型
///
/// ## 字段列表
///
/// | 字段 | 类型 | 说明 |
/// |------|------|------|
/// | id | UUID | 唯一标识符 |
/// | imageData | Data? | 错题图片 |
/// | title | String | 标题 |
/// | note | String | 笔记 |
/// | createdAt | Date | 创建时间 |
/// | updatedAt | Date | 更新时间 |
/// | masteryLevel | Int | 掌握程度 |
/// | nextReviewDate | Date | 下次复习时间 |
/// | reviewCount | Int | 复习次数 |
/// | subjectRaw | String | 学科 |
/// | gradeRaw | String | 年级 |
/// | knowledgePointsRaw | String | 知识点 |
/// | difficultyRaw | Int | 难度 |
/// | errorTypeRaw | String | 错误类型 |
/// | sourceRaw | String | 来源 |
/// | reviewItemTypeRaw | String | 题型 |
enum ReviewItemSchemaV1: VersionedSchema {

    /// 版本标识符
    ///
    /// 格式：(主版本, 次版本, 修订版本)
    /// 使用 `nonisolated(unsafe)` 以兼容 Swift 6.2 严格并发
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(1, 0, 0)

    /// 此版本包含的持久化模型
    static var models: [any PersistentModel.Type] {
        [ReviewItemModel.self]
    }
}

// MARK: - Future Schema Versions

/*
/// ReviewItem Schema V2
///
/// 第二版本示例：添加标签系统
///
/// ## 变更说明
///
/// - 新增 `tags` 字段：自定义标签数组
/// - 新增 `isFavorite` 字段：收藏标记
///
/// ## 迁移注意事项
///
/// - `tags` 默认为空数组
/// - `isFavorite` 默认为 false
enum ReviewItemSchemaV2: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(2, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [ReviewItemModel.self]
    }
}
*/

/*
/// ReviewItem Schema V3
///
/// 第三版本示例：添加同步支持
///
/// ## 变更说明
///
/// - 新增 `syncStatus` 字段：同步状态
/// - 新增 `lastSyncedAt` 字段：最后同步时间
/// - 新增 `cloudId` 字段：云端 ID
enum ReviewItemSchemaV3: VersionedSchema {
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [ReviewItemModel.self]
    }
}
*/

// MARK: - Migration Helpers

extension ReviewItemMigrationPlan {

    /// 当前 Schema 版本
    nonisolated(unsafe) static var currentVersion: Schema.Version {
        ReviewItemSchemaV1.versionIdentifier
    }

    /// 版本描述
    static var versionDescription: String {
        "V\(currentVersion.major).\(currentVersion.minor).\(currentVersion.patch)"
    }
}
