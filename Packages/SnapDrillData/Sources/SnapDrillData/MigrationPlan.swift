//
//  MigrationPlan.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2025/12/31.
//  Updated by SnapDrill Architect on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  SwiftData Schema 定义（首次发布版本，无需迁移计划）
//

import SwiftData
import Foundation

/// 当前 Schema 版本 - V1
public enum SnapDrillSchemaV1: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(1, 0, 0)

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

// MARK: - 未来版本示例（当需要时取消注释）

/*
/// 版本 2 示例 - 添加新字段时使用
public enum SnapDrillSchemaV2: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(2, 0, 0)
    
    public static var models: [any PersistentModel.Type] {
        [
            ReviewItemModel.self,
            SubjectModel.self,
            TagModel.self,
            SourceModel.self
        ]
    }
}

/// 迁移计划示例
public enum SnapDrillMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            SnapDrillSchema.self,
            SnapDrillSchemaV2.self
        ]
    }
    
    public static var stages: [MigrationStage] {
        [
            migrateV1toV2
        ]
    }
    
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SnapDrillSchema.self,
        toVersion: SnapDrillSchemaV2.self
    )
}
*/
