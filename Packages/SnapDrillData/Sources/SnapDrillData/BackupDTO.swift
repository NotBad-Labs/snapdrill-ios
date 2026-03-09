//
//  BackupDTO.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/03/09.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  备份文件的 Codable DTO 定义，用于 JSON 序列化/反序列化。
//

import Foundation

// MARK: - Manifest

/// 备份文件的元数据清单
public struct BackupManifest: Codable, Sendable {
    /// 备份格式版本（用于向前兼容判断）
    public let schemaVersion: Int
    /// 备份创建时间
    public let createdAt: Date
    /// App 版本号（Marketing Version）
    public let appVersion: String
    /// 题目总数
    public let itemCount: Int

    /// 当前 Schema 版本——每次 Model 字段变更时递增
    public static let currentSchemaVersion = 1

    public init(schemaVersion: Int, createdAt: Date, appVersion: String, itemCount: Int) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.itemCount = itemCount
    }
}

// MARK: - Review Item DTO

/// ReviewItemModel 的序列化表示
public struct ReviewItemBackupDTO: Codable, Sendable {
    public let id: UUID
    public let content: String?
    public let imagePath: String?
    public let createdAt: Date
    public let lastReviewedAt: Date
    public let nextReviewAt: Date
    public let subject: String
    public let source: String
    public let tagNames: [String]
    public let answerText: String?
    public let answerImagePath: String?
    public let difficulty: Int
    public let grade: String
    public let easeFactor: Double
    public let interval: Int
    public let repetitions: Int
}

// MARK: - Subject DTO

/// SubjectModel 的序列化表示
public struct SubjectBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int
}

// MARK: - Source DTO

/// SourceModel 的序列化表示
public struct SourceBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int
}

// MARK: - Grade DTO

/// GradeModel 的序列化表示
public struct GradeBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let sortOrder: Int
}

// MARK: - Tag DTO

/// TagModel 的序列化表示
public struct TagBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let colorHex: String
}

// MARK: - Top-level Payload

/// 备份文件中 data.json 的顶层结构
public struct BackupPayload: Codable, Sendable {
    public let reviewItems: [ReviewItemBackupDTO]
    public let subjects: [SubjectBackupDTO]
    public let sources: [SourceBackupDTO]
    public let grades: [GradeBackupDTO]
    public let tags: [TagBackupDTO]

    public init(
        reviewItems: [ReviewItemBackupDTO],
        subjects: [SubjectBackupDTO],
        sources: [SourceBackupDTO],
        grades: [GradeBackupDTO],
        tags: [TagBackupDTO]
    ) {
        self.reviewItems = reviewItems
        self.subjects = subjects
        self.sources = sources
        self.grades = grades
        self.tags = tags
    }
}

// MARK: - Model → DTO Conversion

extension ReviewItemModel {
    /// 转换为备份 DTO（纯值类型，可跨 actor 传递）
    @MainActor
    func toBackupDTO() -> ReviewItemBackupDTO {
        ReviewItemBackupDTO(
            id: id,
            content: content,
            imagePath: imagePath,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt,
            subject: subject,
            source: source,
            tagNames: tags?.map(\.name) ?? [],
            answerText: answerText,
            answerImagePath: answerImagePath,
            difficulty: difficulty,
            grade: grade,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions
        )
    }
}

extension SubjectModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> SubjectBackupDTO {
        SubjectBackupDTO(id: id, name: name, icon: icon, colorHex: colorHex, sortOrder: sortOrder)
    }
}

extension SourceModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> SourceBackupDTO {
        SourceBackupDTO(id: id, name: name, icon: icon, colorHex: colorHex, sortOrder: sortOrder)
    }
}

extension GradeModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> GradeBackupDTO {
        GradeBackupDTO(id: id, name: name, sortOrder: sortOrder)
    }
}

extension TagModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> TagBackupDTO {
        TagBackupDTO(id: id, name: name, colorHex: colorHex)
    }
}
