//
//  BackupDTO.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  备份文件的 Codable DTO 定义，用于 JSON 序列化/反序列化。
//  L3 动态维度重构基线：分类经动态维度（dimensions + categoryValues），资料项持 categoryValueIds。
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
    /// 所有 Profile 资料项总数
    public let totalItemCount: Int
    /// 备份中包含的 Profile 数量
    public let profileCount: Int
    /// 所有 Profile 名称
    public let profileNames: [String]

    /// 当前备份 Schema 版本。
    ///
    /// **版本历史**：
    /// - 1 → 动态维度系统重构基线（零用户阶段重置；旧 v1–v4 备份不再兼容，删除向后兼容容错）。
    /// - 2 → 移除静态 `difficulty` 字段，级别 / 难度等属性统一经动态维度表达。
    ///
    /// 注：备份 Schema 与 SwiftData Schema 独立管理；版本机制保留，待有真实用户后再递增。
    public static let currentSchemaVersion = 2

    public init(schemaVersion: Int, createdAt: Date, appVersion: String, totalItemCount: Int, profileCount: Int, profileNames: [String]) {
        self.schemaVersion = schemaVersion
        self.createdAt = createdAt
        self.appVersion = appVersion
        self.totalItemCount = totalItemCount
        self.profileCount = profileCount
        self.profileNames = profileNames
    }
}

// MARK: - Archive Item DTO

/// ArchiveItemModel 的序列化表示。分类经 `categoryValueIds`（指向 CategoryValueBackupDTO）。
nonisolated public struct ArchiveItemBackupDTO: Codable, Sendable {
    public let id: UUID
    public let content: String?
    public let imagePath: String?
    public let createdAt: Date
    public let lastReviewedAt: Date
    public let nextReviewAt: Date
    public let answerText: String?
    public let answerImagePath: String?
    public let easeFactor: Double
    public let interval: Int
    public let repetitions: Int
    /// 该资料项挂载的维度值 id（A2 动态维度）
    public let categoryValueIds: [UUID]

    public init(
        id: UUID,
        content: String?,
        imagePath: String?,
        createdAt: Date,
        lastReviewedAt: Date,
        nextReviewAt: Date,
        answerText: String?,
        answerImagePath: String?,
        easeFactor: Double,
        interval: Int,
        repetitions: Int,
        categoryValueIds: [UUID]
    ) {
        self.id = id
        self.content = content
        self.imagePath = imagePath
        self.createdAt = createdAt
        self.lastReviewedAt = lastReviewedAt
        self.nextReviewAt = nextReviewAt
        self.answerText = answerText
        self.answerImagePath = answerImagePath
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.categoryValueIds = categoryValueIds
    }
}

// MARK: - Category Dimension DTO

/// CategoryDimensionModel 的序列化表示
nonisolated public struct CategoryDimensionBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let isMultiValue: Bool
    public let isBuiltIn: Bool
    public let systemKey: String?
    public let sortOrder: Int
    public let icon: String

    public init(id: UUID, name: String, isMultiValue: Bool, isBuiltIn: Bool, systemKey: String?, sortOrder: Int, icon: String) {
        self.id = id
        self.name = name
        self.isMultiValue = isMultiValue
        self.isBuiltIn = isBuiltIn
        self.systemKey = systemKey
        self.sortOrder = sortOrder
        self.icon = icon
    }
}

// MARK: - Category Value DTO

/// CategoryValueModel 的序列化表示（dimensionId 指向所属维度）
nonisolated public struct CategoryValueBackupDTO: Codable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorHex: String
    public let sortOrder: Int
    public let createdAt: Date
    public let dimensionId: UUID?

    public init(id: UUID, name: String, icon: String, colorHex: String, sortOrder: Int, createdAt: Date, dimensionId: UUID?) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.dimensionId = dimensionId
    }
}

// MARK: - Profile Backup Data

/// 单个 Profile 的备份数据
nonisolated public struct ProfileBackupData: Codable, Sendable {
    public let profileName: String
    public let profileId: UUID
    public let reviewItems: [ArchiveItemBackupDTO]
    public let dimensions: [CategoryDimensionBackupDTO]
    public let categoryValues: [CategoryValueBackupDTO]

    public init(
        profileName: String,
        profileId: UUID,
        reviewItems: [ArchiveItemBackupDTO],
        dimensions: [CategoryDimensionBackupDTO],
        categoryValues: [CategoryValueBackupDTO]
    ) {
        self.profileName = profileName
        self.profileId = profileId
        self.reviewItems = reviewItems
        self.dimensions = dimensions
        self.categoryValues = categoryValues
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

extension ArchiveItemModel {
    /// 转换为备份 DTO（纯值类型，可跨 actor 传递）
    func toBackupDTO() -> ArchiveItemBackupDTO {
        ArchiveItemBackupDTO(
            id: id,
            content: content,
            imagePath: imagePath,
            createdAt: createdAt,
            lastReviewedAt: lastReviewedAt,
            nextReviewAt: nextReviewAt,
            answerText: answerText,
            answerImagePath: answerImagePath,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions,
            categoryValueIds: (categoryValues ?? []).map { $0.id }
        )
    }
}

extension CategoryDimensionModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> CategoryDimensionBackupDTO {
        CategoryDimensionBackupDTO(
            id: id, name: name, isMultiValue: isMultiValue, isBuiltIn: isBuiltIn,
            systemKey: systemKey, sortOrder: sortOrder, icon: icon
        )
    }
}

extension CategoryValueModel {
    /// 转换为备份 DTO
    func toBackupDTO() -> CategoryValueBackupDTO {
        CategoryValueBackupDTO(
            id: id, name: name, icon: icon, colorHex: colorHex,
            sortOrder: sortOrder, createdAt: createdAt, dimensionId: dimension?.id
        )
    }
}
