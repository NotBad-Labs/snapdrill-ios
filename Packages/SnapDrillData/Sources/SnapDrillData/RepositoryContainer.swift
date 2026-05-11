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

    /// 创建仓库容器（推荐路径）
    /// - Parameter executor: DataExecutor，向所有子仓库传递其 mainContext
    public init(executor: DataExecutor) {
        self.review = ReviewRepository(executor: executor)
        self.subject = SubjectRepository(executor: executor)
        self.source = SourceRepository(executor: executor)
        self.tag = TagRepository(executor: executor)
        self.grade = GradeRepository(executor: executor)
    }

    /// 创建仓库容器（向后兼容测试/Preview 中的显式 ModelContext）
    /// - Parameter modelContext: 共享的 ModelContext
    public init(modelContext: ModelContext) {
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
            try? await storage.deleteImage(path: path) // best-effort: 单张删除失败不中断整批清理
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
    public func collectProfileBackupData(profileName: String, profileId: UUID) throws -> ProfileBackupData {
        let items = try review.fetchAllModels()
        let allSubjects = try subject.fetchAllModels()
        let allSources = try source.fetchAllModels()
        let allGrades = try grade.fetchAllModels()
        let allTags = try tag.fetchAllModels()

        return ProfileBackupData(
            profileName: profileName,
            profileId: profileId,
            reviewItems: items.map { $0.toBackupDTO() },
            subjects: allSubjects.map { $0.toBackupDTO() },
            sources: allSources.map { $0.toBackupDTO() },
            grades: allGrades.map { $0.toBackupDTO() },
            tags: allTags.map { $0.toBackupDTO() }
        )
    }

    /// 从备份 DTO 恢复全量数据（单次 saveContext 原子操作）
    ///
    /// delete + insert 在同一 saveContext 内完成。失败时 rollback 同时撤销两者。
    /// 恢复前强制备份当前数据到持久 Recovery 目录，备份失败直接拒绝恢复。
    ///
    /// - Parameter profileData: 单个 Profile 的备份数据
    public func restoreFromProfileData(_ profileData: ProfileBackupData) async throws {
        // 0. 强制安全网备份，失败直接拒绝恢复
        let recoveryURL = try saveRecoveryBackup()

        // 1. 收集旧图片路径（恢复成功后才清理）
        let oldImagePaths = try review.collectAllImagePaths()

        // 2. 内存标记删除（不 save）
        try review.deleteAll()
        try deleteAllTaxonomyInMemory()

        do {
            // 3. 内存插入备份数据（不 save）
            for dto in profileData.subjects {
                let model = SubjectModel(id: dto.id, name: dto.name, icon: dto.icon, colorHex: dto.colorHex, sortOrder: dto.sortOrder)
                subject.insert(model)
            }
            for dto in profileData.sources {
                let model = SourceModel(id: dto.id, name: dto.name, icon: dto.icon, colorHex: dto.colorHex, sortOrder: dto.sortOrder)
                source.insert(model)
            }
            for dto in profileData.grades {
                let model = GradeModel(id: dto.id, name: dto.name, sortOrder: dto.sortOrder)
                grade.insert(model)
            }

            var tagsByName: [String: TagModel] = [:]
            for dto in profileData.tags {
                let model = try tag.fetchOrCreateModel(name: dto.name, colorHex: dto.colorHex)
                tagsByName[dto.name] = model
            }

            for dto in profileData.reviewItems {
                let itemTags = dto.tagNames.compactMap { tagsByName[$0] }
                let model = ReviewItemModel(
                    id: dto.id, content: dto.content, imagePath: dto.imagePath,
                    createdAt: dto.createdAt, lastReviewedAt: dto.lastReviewedAt,
                    nextReviewAt: dto.nextReviewAt, subject: dto.subject, source: dto.source,
                    tags: itemTags, answerText: dto.answerText, answerImagePath: dto.answerImagePath,
                    difficulty: dto.difficulty, grade: dto.grade,
                    easeFactor: dto.easeFactor, interval: dto.interval, repetitions: dto.repetitions
                )
                review.insert(model)
            }

            // 4. 单次 saveContext：delete+insert 原子提交。失败 rollback 同时撤销两者
            try review.saveContext()

            // 5. 成功后清理旧图片（best-effort）
            let storage = ImageStorage()
            for path in oldImagePaths {
                try? await storage.deleteImage(path: path)
            }

            // 6. 清理安全网备份
            try? FileManager.default.removeItem(at: recoveryURL)

        } catch {
            review.rollbackContext()
            SnapDrillLogger.data.error("恢复失败，数据已回滚。安全网备份保留在: \(recoveryURL.path)")
            throw error
        }
    }

    // MARK: - Recovery Backup

    private static var recoveryDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return appSupport.appendingPathComponent("SnapDrill/Recovery")
    }

    private func saveRecoveryBackup() throws -> URL {
        let dir = Self.recoveryDirectory
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let timestamp = ISO8601DateFormatter().string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let url = dir.appendingPathComponent("pre_restore_\(timestamp).json")
        let backup = try collectProfileBackupData(profileName: "recovery_backup", profileId: UUID())
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try encoder.encode(backup).write(to: url, options: .atomic)
        SnapDrillLogger.data.info("恢复前安全网备份已保存: \(url.lastPathComponent)")
        return url
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
        let executor = DataExecutor(inMemory: true)

        self.review = ReviewRepository(executor: executor)
        self.subject = SubjectRepository(executor: executor)
        self.source = SourceRepository(executor: executor)
        self.tag = TagRepository(executor: executor)
        self.grade = GradeRepository(executor: executor)
    }
}
