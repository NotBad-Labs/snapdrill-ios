//
//  ReviewItemMigrationPlan.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftData
import Foundation
import ReviewKit

// MARK: - ReviewItemMigrationPlan

/// ReviewItem 数据迁移计划
///
/// 负责管理不同版本之间的 SwiftData 数据迁移。
/// V3 架构：图片存储在文件系统，数据库只存路径。
enum ReviewItemMigrationPlan: SchemaMigrationPlan {

    // MARK: - Schema Versions

    static var schemas: [VersionedSchema.Type] {
        [
            ReviewItemSchemaV3.self
        ]
    }

    // MARK: - Migration Stages

    static var stages: [MigrationStage] {
        []
    }
}

// MARK: - ReviewItemSchemaV3

/// ReviewItem Schema V3
///
/// 实用主义架构版本：
/// - 图片存储在文件系统（Documents/Images/）
/// - 数据库只存储图片路径 `imagePath: String?`
/// - 简化模型，删除中间层
enum ReviewItemSchemaV3: VersionedSchema {
    
    nonisolated(unsafe) static var versionIdentifier = Schema.Version(3, 0, 0)
    
    static var models: [any PersistentModel.Type] {
        [ReviewItemModel.self]
    }
}

// MARK: - Migration Helpers

extension ReviewItemMigrationPlan {

    nonisolated(unsafe) static var currentVersion: Schema.Version {
        ReviewItemSchemaV3.versionIdentifier
    }

    static var versionDescription: String {
        "V\(currentVersion.major).\(currentVersion.minor).\(currentVersion.patch)"
    }
}
