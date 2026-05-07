//
//  MigrationPlan.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData Schema 定义与迁移计划。
//

import SwiftData
import Foundation

/// Schema V1（1.0.0）— v1.0 发布基线
///
/// 包含所有 Model 的完整定义。`#Unique` 不可用（CloudKit 不兼容），
/// 名称唯一性由 Repository 层业务逻辑保证（DataError.duplicateName）。
public enum SnapDrillSchemaV1: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(1, 0, 0)

    // `any PersistentModel.Type` 和 `any VersionedSchema.Type` 是 SwiftData 框架强制要求的 API 签名，
    // 属于"框架强制 any"例外，不违反项目禁止 any existentials 的原则。
    public static var models: [any PersistentModel.Type] {
        [
            ReviewItemModel.self,
            SubjectModel.self,
            TagModel.self,
            SourceModel.self,
            GradeModel.self
        ]
    }
}

/// 迁移计划
///
/// 当前仅 V1（v1.0 发布基线）。未来 Schema 变更时按以下步骤操作：
///
/// ### 添加 Schema V2 的步骤（参考 [Apple 官方文档](https://developer.apple.com/documentation/swiftdata/schemamigrationplan)）
///
/// 1. 创建 `SnapDrillSchemaV2`，遵循 `VersionedSchema`，设置 `versionIdentifier = .init(2, 0, 0)`
/// 2. 在 `models` 中声明新版本的 Model 类型（若有新增/变更属性，用新的 Model 类型名）
/// 3. 在 `schemas` 中添加 `SnapDrillSchemaV2.self`
/// 4. 在 `stages` 中添加 MigrationStage（lightweight 或 custom）
///
/// ### 示例（取消注释即用）：
/// ```swift
/// // V2 schema
/// public enum SnapDrillSchemaV2: VersionedSchema {
///     public static let versionIdentifier: Schema.Version = .init(2, 0, 0)
///     public static var models: [any PersistentModel.Type] {
///         [ReviewItemModel.self, SubjectModel.self, TagModel.self,
///          SourceModel.self, GradeModel.self]
///     }
/// }
///
/// // 在 SnapDrillMigrationPlan 中：
/// public static var schemas: [any VersionedSchema.Type] {
///     [SnapDrillSchemaV1.self, SnapDrillSchemaV2.self]
/// }
/// public static var stages: [MigrationStage] {
///     [migrateV1toV2]
/// }
/// static let migrateV1toV2 = MigrationStage.lightweight(
///     fromVersion: SnapDrillSchemaV1.self,
///     toVersion: SnapDrillSchemaV2.self
/// )
/// ```
public enum SnapDrillMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SnapDrillSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
