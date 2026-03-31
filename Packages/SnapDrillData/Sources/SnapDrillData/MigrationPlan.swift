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
/// v1.0 发布前无存量用户，仅保留单一 Schema 版本。
/// 未来需要 Schema 变更时，新增 V2 并添加 MigrationStage。
public enum SnapDrillMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SnapDrillSchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
