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
nonisolated public struct BackupManifest: Codable, Sendable {
    /// 备份格式版本（用于向前兼容判断）
    public let schemaVersion: Int
    /// 备份创建时间
    public let createdAt: Date
    /// App 版本号（Marketing Version）
    public let appVersion: String
    /// 所有 Profile 题目总数
    public let totalItemCount: Int
    /// 备份中包含的 Profile 数量
    public let profileCount: Int
    /// 所有 Profile 名称
    public let profileNames: [String]

    /// 当前备份 Schema 版本——每次 BackupDTO 字段变更时递增
    ///
    /// 备份 Schema 与 SwiftData Schema 独立管理：版本变更不一定同步。
    ///
    /// **版本历史**：
    /// - 1 → 初始备份格式
    /// - 2 → Tag/Subject/Source/Grade 字段扩展
    /// - 3 → Multi-Profile：新增 profileName 字段（单 Profile）
    /// - 4 → 全 Profile 备份：profiles 数组结构（#531）
    public static let currentSchemaVersion = 4

    public init(schemaVersion: Int, createdAt: Date, appVersion: String, totalItemCount: Int, profileCount: Int, profileNames: [String]) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.totalItemCount = totalItemCount
        self.profileCount = profileCount
        self.profileNames = profileNames
    }
}

// MARK: - Review Item DTO

/// ReviewItemModel 的序列化表示
///
/// 使用自定义 `init(from:)` + `decodeIfPresent` 确保新增字段时，
/// 旧版本备份文件（缺少新字段）仍可正常解析。
nonisolated public struct ReviewItemBackupDTO: Codable, Sendable {
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

    // 新增字段在此追加，init(from:) 中用 decodeIfPresent + 默认值即可兼容旧备份

    public init(
        id: UUID,
        content: String?,
        imagePath: String?,
        createdAt: Date,
        lastReviewedAt: Date,
        nextReviewAt: Date,
        subject: String,
        source: String,
        tagNames: [String],
        answerText: String?,
        answerImagePath: String?,
        difficulty: Int,
        grade: String,
        easeFactor: Double,
        interval: Int,
        repetitions: Int
    ) {
        self.id = id
        self.content = content
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.subject = subject
        self.source = source
        self.tagNames = tagNames
        self.answerText = answerText
        self.answerImagePath = answerImagePath
        self.difficulty = difficulty
        self.grade = grade
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        content = try c.decodeIfPresent(String.self, forKey: .content)
        imagePath = try c.decodeIfPresent(String.self, forKey: .imagePath)
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
        lastReviewedAt = try c.decodeIfPresent(Date.self, forKey: .lastReviewedAt) ?? .distantPast
        nextReviewAt = try c.decodeIfPresent(Date.self, forKey: .nextReviewAt) ?? .distantPast
        subject = try c.decodeIfPresent(String.self, forKey: .subject) ?? "其他"
        source = try c.decodeIfPresent(String.self, forKey: .source) ?? "其他"
        tagNames = try c.decodeIfPresent([String].self, forKey: .tagNames) ?? []
        answerText = try c.decodeIfPresent(String.self, forKey: .answerText)
        answerImagePath = try c.decodeIfPresent(String.self, forKey: .answerImagePath)
        difficulty = try c.decodeIfPresent(Int.self, forKey: .difficulty) ?? 1
        grade = try c.decodeIfPresent(String.self, forKey: .grade) ?? ""
        easeFactor = try c.decodeIfPresent(Double.self, forKey: .easeFactor) ?? 2.5
        interval = try c.decodeIfPresent(Int.self, forKey: .interval) ?? 0
        repetitions = try c.decodeIfPresent(Int.self, forKey: .repetitions) ?? 0
    }
}

// MARK: - Subject DTO

/// SubjectModel 的序列化表示
nonisolated public struct SubjectBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int

    public init(id: UUID, name: String, icon: String, colorHex: String, sortOrder: Int) {
        self.id = id; self.name = name; self.icon = icon; self.colorHex = colorHex; self.sortOrder = sortOrder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "book.fill"
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}

// MARK: - Source DTO

/// SourceModel 的序列化表示
nonisolated public struct SourceBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int

    public init(id: UUID, name: String, icon: String, colorHex: String, sortOrder: Int) {
        self.id = id; self.name = name; self.icon = icon; self.colorHex = colorHex; self.sortOrder = sortOrder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        icon = try c.decodeIfPresent(String.self, forKey: .icon) ?? "doc.text.fill"
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}

// MARK: - Grade DTO

/// GradeModel 的序列化表示
nonisolated public struct GradeBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let sortOrder: Int

    public init(id: UUID, name: String, sortOrder: Int) {
        self.id = id; self.name = name; self.sortOrder = sortOrder
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        sortOrder = try c.decodeIfPresent(Int.self, forKey: .sortOrder) ?? 0
    }
}

// MARK: - Tag DTO

/// TagModel 的序列化表示
nonisolated public struct TagBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let colorHex: String

    public init(id: UUID, name: String, colorHex: String) {
        self.id = id; self.name = name; self.colorHex = colorHex
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        colorHex = try c.decodeIfPresent(String.self, forKey: .colorHex) ?? "#007AFF"
    }
}

// MARK: - Profile Backup Data

/// 单个 Profile 的备份数据
nonisolated public struct ProfileBackupData: Codable, Sendable {
    public let profileName: String
    public let profileId: UUID
    public let reviewItems: [ReviewItemBackupDTO]
    public let subjects: [SubjectBackupDTO]
    public let sources: [SourceBackupDTO]
    public let grades: [GradeBackupDTO]
    public let tags: [TagBackupDTO]

    public init(
        profileName: String,
        profileId: UUID,
        reviewItems: [ReviewItemBackupDTO],
        subjects: [SubjectBackupDTO],
        sources: [SourceBackupDTO],
        grades: [GradeBackupDTO],
        tags: [TagBackupDTO]
    ) {
        self.profileName = profileName
        self.profileId = profileId
        self.reviewItems = reviewItems
        self.subjects = subjects
        self.sources = sources
        self.grades = grades
        self.tags = tags
    }
}

// MARK: - Top-level Payload

/// 备份文件中 data.json 的顶层结构（全 Profile）
nonisolated public struct BackupPayload: Codable, Sendable {
    public let profiles: [ProfileBackupData]

    public init(profiles: [ProfileBackupData]) {
        self.profiles = profiles
    }
}

// MARK: - Model → DTO Conversion

extension ReviewItemModel {
    /// 转换为备份 DTO（纯值类型，可跨 actor 传递）
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
