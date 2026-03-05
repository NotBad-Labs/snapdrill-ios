//
//  MigrationPlan.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/31.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SwiftData 数据迁移计划，管理各版本 Schema 变更。
//

import SwiftData
import Foundation

/// Schema V1（1.0.0）— 初始版本
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

/// Schema V2（2.0.0）— nextReviewAt / lastReviewedAt 由 Date? 改为 Date（默认 distantPast）
/// SwiftData lightweight 迁移自动将现有 NULL 列填充为模型默认值 Date.distantPast，
/// 消除 Optional<Date> 的 #Predicate 转译 Bug 导致的全表扫描内存炸弹。
public enum SnapDrillSchemaV2: VersionedSchema {
    public static let versionIdentifier: Schema.Version = .init(2, 0, 0)

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

/// 迁移计划：V1 → V2（lightweight，无自定义数据转换）
public enum SnapDrillMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SnapDrillSchemaV1.self, SnapDrillSchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // lightweight 迁移：SwiftData 自动将 nextReviewAt/lastReviewedAt 的 NULL 值
    // 填充为 Date.distantPast（模型中声明的默认值），无需手动数据转换。
    static let migrateV1toV2 = MigrationStage.lightweight(
        fromVersion: SnapDrillSchemaV1.self,
        toVersion: SnapDrillSchemaV2.self
    )
}
