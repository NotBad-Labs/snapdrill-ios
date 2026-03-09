//
//  RepositoryContainer.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  仓库容器，聚合所有 Repository 并提供统一数据清理入口。
//

import Foundation
import SwiftData
import SnapDrillCore

// MARK: - Default Implementation

/// 数据仓库容器（具体类，直接注入到 SwiftUI Environment）
@MainActor
public final class RepositoryContainer {
    /// 复习题目仓库
    public let review: ReviewRepository
    /// 学科分类仓库
    public let subject: SubjectRepository
    /// 来源分类仓库
    public let source: SourceRepository
    /// 标签仓库
    public let tag: TagRepository
    /// 年级分类仓库
    public let grade: GradeRepository

    // MARK: - Initialization

    /// 创建仓库容器
    /// - Parameter modelContext: 共享的 ModelContext，默认使用 `PersistenceController.shared.container.mainContext`
    public init(modelContext: ModelContext = PersistenceController.shared.container.mainContext) {
        self.review = ReviewRepository(modelContext: modelContext)
        self.subject = SubjectRepository(modelContext: modelContext)
        self.source = SourceRepository(modelContext: modelContext)
        self.tag = TagRepository(modelContext: modelContext)
        self.grade = GradeRepository(modelContext: modelContext)
    }

    // MARK: - 跨仓库协调操作

    /// 原子删除所有复习数据与分类数据。
    /// 先收集图片路径，再批量内存删除，统一 save 一次；
    /// save 成功后清理图片文件（文件操作不可回滚，仅 best-effort）；
    /// save 失败时 rollback，数据库记录全部还原。
    public func deleteAllData() async throws {
        let imagePaths = try review.collectAllImagePaths()
        try review.deleteAll()
        try deleteAllTaxonomyInMemory()
        do {
            try review.saveContext()
        } catch {
            review.rollbackContext()
            throw error
        }
        // save 成功后清理图片文件（best-effort，async 避免阻塞主线程）
        let storage = ImageStorage()
        for path in imagePaths {
            try? await storage.deleteImage(path: path)
        }
    }

    /// 原子删除所有分类数据（学科、来源、标签、年级）。
    public func deleteAllTaxonomy() throws {
        try deleteAllTaxonomyInMemory()
        do {
            try review.saveContext()
        } catch {
            review.rollbackContext()
            throw error
        }
    }

    // MARK: - Backup / Restore

    /// 收集全量备份数据（转换为 Sendable DTO）
    ///
    /// 在 MainActor 上读取所有 @Model 数据并转为值类型 DTO，
    /// 供 BackupService（actor）在后台线程打包 ZIP。
    public func collectBackupPayload() throws -> BackupPayload {
        let items = try review.fetchAllModels()
        let allSubjects = try subject.fetchAllModels()
        let allSources = try source.fetchAllModels()
        let allGrades = try grade.fetchAllModels()
        let allTags = try tag.fetchAllModels()

        return BackupPayload(
            reviewItems: items.map { $0.toBackupDTO() },
            subjects: allSubjects.map { $0.toBackupDTO() },
            sources: allSources.map { $0.toBackupDTO() },
            grades: allGrades.map { $0.toBackupDTO() },
            tags: allTags.map { $0.toBackupDTO() }
        )
    }

    /// 从备份 DTO 恢复全量数据
    ///
    /// 先删除所有现有数据（含图片文件），再从 DTO 重建全部 Model 和关系。
    /// 整个数据库操作是原子的：insert 全部完成后统一 save，失败时 rollback。
    ///
    /// - Parameter payload: 反序列化后的备份数据
    public func restoreFromPayload(_ payload: BackupPayload) async throws {
        // 1. 删除全部现有数据
        try await deleteAllData()

        // 2. 重建分类模型
        for dto in payload.subjects {
            let model = SubjectModel(id: dto.id, name: dto.name, icon: dto.icon, colorHex: dto.colorHex, sortOrder: dto.sortOrder)
            subject.insert(model)
        }
        for dto in payload.sources {
            let model = SourceModel(id: dto.id, name: dto.name, icon: dto.icon, colorHex: dto.colorHex, sortOrder: dto.sortOrder)
            source.insert(model)
        }
        for dto in payload.grades {
            let model = GradeModel(id: dto.id, name: dto.name, sortOrder: dto.sortOrder)
            grade.insert(model)
        }

        // 3. 重建标签（先创建，后续用于关联）
        var tagsByName: [String: TagModel] = [:]
        for dto in payload.tags {
            let model = try tag.fetchOrCreateModel(name: dto.name, colorHex: dto.colorHex)
            tagsByName[dto.name] = model
        }

        // 4. 重建题目并关联标签
        for dto in payload.reviewItems {
            let itemTags = dto.tagNames.compactMap { tagsByName[$0] }
            let model = ReviewItemModel(
                id: dto.id,
                content: dto.content,
                imagePath: dto.imagePath,
                createdAt: dto.createdAt,
                lastReviewedAt: dto.lastReviewedAt,
                nextReviewAt: dto.nextReviewAt,
                subject: dto.subject,
                source: dto.source,
                tags: itemTags,
                answerText: dto.answerText,
                answerImagePath: dto.answerImagePath,
                difficulty: dto.difficulty,
                grade: dto.grade,
                easeFactor: dto.easeFactor,
                interval: dto.interval,
                repetitions: dto.repetitions
            )
            review.insert(model)
        }

        // 5. 原子持久化
        do {
            try review.saveContext()
        } catch {
            review.rollbackContext()
            throw error
        }
    }

    // MARK: - Private Helpers

    /// 纯内存操作：标记所有分类数据待删除，不 save。
    private func deleteAllTaxonomyInMemory() throws {
        try subject.deleteAll()
        try source.deleteAll()
        try tag.deleteAll()
        try grade.deleteAll()
    }
}

// MARK: - Preview Support

/// 预览专用数据仓库容器（使用内存 ModelContainer）
@MainActor
public final class PreviewRepositoryContainer {
    /// 复习题目仓库
    public let review: ReviewRepository
    /// 学科分类仓库
    public let subject: SubjectRepository
    /// 来源分类仓库
    public let source: SourceRepository
    /// 标签仓库
    public let tag: TagRepository
    /// 年级分类仓库
    public let grade: GradeRepository

    /// 创建内存预览容器
    public init() {
        let schema = Schema([
            ReviewItemModel.self,
            SubjectModel.self,
            SourceModel.self,
            TagModel.self,
            GradeModel.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        // swiftlint:disable:next force_try
        let container = try! ModelContainer(for: schema, configurations: [config])
        let context = container.mainContext

        self.review = ReviewRepository(modelContext: context)
        self.subject = SubjectRepository(modelContext: context)
        self.source = SourceRepository(modelContext: context)
        self.tag = TagRepository(modelContext: context)
        self.grade = GradeRepository(modelContext: context)
    }
}
