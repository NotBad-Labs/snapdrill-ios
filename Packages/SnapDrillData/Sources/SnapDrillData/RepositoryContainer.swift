//
//  RepositoryContainer.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
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
    /// 归档资料仓库
    public let archive: ArchiveRepository
    /// 分类维度仓库（L3）
    public let dimension: CategoryDimensionRepository
    /// 维度值仓库（L3）
    public let categoryValue: CategoryValueRepository

    // MARK: - Initialization

    /// 生产路径必须保活 DataExecutor；其内部 ModelContainer 是各 repository 的 ModelContext 根所有者。
    private let executor: DataExecutor?

    /// 唯一资料库根目录。
    public let libraryDirectory: URL
    /// 与仓库共享同一根目录的图片存储。
    public let imageStorage: ImageStorage

    /// 创建仓库容器（生产路径）
    /// - Parameters:
    ///   - executor: DataExecutor，向所有子仓库传递其 mainContext
    ///   - libraryDirectory: 唯一资料库根目录（用于图片操作）
    public init(executor: DataExecutor, libraryDirectory: URL) {
        self.executor = executor
        self.libraryDirectory = libraryDirectory
        let imageStorage = ImageStorage(baseDirectory: libraryDirectory)
        self.imageStorage = imageStorage
        self.dimension = CategoryDimensionRepository(executor: executor)
        self.categoryValue = CategoryValueRepository(executor: executor)
        self.archive = ArchiveRepository(
            executor: executor,
            imageStorageFactory: { imageStorage }
        )
    }

    /// 创建仓库容器（测试/Preview 路径，scope 使用占位值）
    /// - Parameter modelContext: 共享的 ModelContext
    public init(modelContext: ModelContext) {
        self.executor = nil
        self.libraryDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("SnapDrill-Repository-\(UUID().uuidString)", isDirectory: true)
        self.imageStorage = ImageStorage(baseDirectory: libraryDirectory)
        self.archive = ArchiveRepository(modelContext: modelContext)
        self.dimension = CategoryDimensionRepository(modelContext: modelContext)
        self.categoryValue = CategoryValueRepository(modelContext: modelContext)
    }

    // MARK: - Private

    // MARK: - 跨仓库协调操作

    /// 原子删除所有归档资料与分类数据。
    /// 先收集图片路径，再批量内存删除，统一 save 一次；
    /// save 成功后清理图片文件（文件操作不可回滚，仅 best-effort）；
    /// save 失败时 rollback，数据库记录全部还原。
    public func deleteAllData() async throws {
        let imagePaths = try archive.collectAllImagePaths()
        try archive.deleteAll()
        try deleteAllTaxonomyInMemory()
        do {
            try archive.saveContext()
        } catch {
            archive.rollbackContext()
            throw error
        }
        // save 成功后清理图片文件（best-effort，async 避免阻塞主线程）
        for path in imagePaths {
            try? await imageStorage.deleteImage(path: path) // best-effort: 单张删除失败不中断整批清理
        }
    }

    /// 原子删除所有分类数据（分类、来源、标签、级别）。
    public func deleteAllTaxonomy() throws {
        // 先解所有资料项对维度值的反向引用——批量 deleteAll 不跑 per-item detach，
        // 否则幸存资料项 categoryValues 残留悬挂引用（desync）。
        // deleteAllData/restore 已先删资料项，不经此路径，不受影响。
        let items = try archive.fetchAllModels()
        for item in items {
            item.categoryValues = []
        }
        try deleteAllTaxonomyInMemory()
        do {
            try archive.saveContext()
        } catch {
            archive.rollbackContext()
            throw error
        }
    }

    // MARK: - Backup / Restore

    /// 收集全量备份数据（转换为 Sendable DTO）
    ///
    /// 在 MainActor 上读取所有 @Model 数据并转为值类型 DTO，
    /// 供 BackupService（actor）在后台线程打包 ZIP。
    public func collectBackupData() throws -> BackupPayload {
        let items = try archive.fetchAllModels()
        let allDimensions = try dimension.fetchAllModels()
        let allValues = allDimensions.flatMap { categoryValue.fetchAllModels(in: $0) }

        return BackupPayload(
            reviewItems: items.map { $0.toBackupDTO() },
            dimensions: allDimensions.map { $0.toBackupDTO() },
            categoryValues: allValues.map { $0.toBackupDTO() }
        )
    }

    /// 从备份 DTO 恢复全量数据（单次 saveContext 原子操作）
    ///
    /// 不再分两步（先 deleteAllData 再重建），而是在同一个 saveContext 内完成
    /// 删除旧数据 + 插入新数据。saveContext 失败时 rollback 会同时撤销删除和插入，
    /// 不会出现"旧数据已删、新数据未写入"的中间状态。
    ///
    /// - Parameter payload: 唯一资料库的备份数据
    /// - Returns: 恢复前数据库引用的图片路径，供协调器在图片恢复成功后清理。
    @discardableResult
    public func restore(from payload: BackupPayload) async throws -> Set<String> {
        // 1. 收集旧图片路径（用于恢复成功后清理）
        let oldImagePaths = try archive.collectAllImagePaths()

        // 2. 在内存中标记删除所有现有数据（不 save）
        try archive.deleteAll()
        try deleteAllTaxonomyInMemory()

        do {
            // 3. 在内存中插入备份数据（不 save）。顺序：维度 → 值（关联维度）→ 资料项（按 id 挂值）
            var dimensionsById: [UUID: CategoryDimensionModel] = [:]
            for dto in payload.dimensions {
                let model = CategoryDimensionModel(
                    id: dto.id, name: dto.name, isMultiValue: dto.isMultiValue,
                    isBuiltIn: dto.isBuiltIn, systemKey: dto.systemKey, sortOrder: dto.sortOrder, icon: dto.icon
                )
                dimension.insert(model)
                dimensionsById[dto.id] = model
            }

            var valuesById: [UUID: CategoryValueModel] = [:]
            for dto in payload.categoryValues {
                let model = CategoryValueModel(
                    id: dto.id, name: dto.name, icon: dto.icon, colorHex: dto.colorHex,
                    sortOrder: dto.sortOrder, createdAt: dto.createdAt,
                    dimension: dto.dimensionId.flatMap { dimensionsById[$0] }
                )
                categoryValue.insert(model)
                valuesById[dto.id] = model
            }

            // 重建资料项（旧裸字符串字段用默认；分类经 categoryValues）
            for dto in payload.reviewItems {
                let model = ArchiveItemModel(
                    id: dto.id,
                    content: dto.content,
                    imagePath: sanitizedImagePath(dto.imagePath),
                    createdAt: dto.createdAt,
                    lastReviewedAt: dto.lastReviewedAt,
                    nextReviewAt: dto.nextReviewAt,
                    answerText: dto.answerText,
                    answerImagePath: sanitizedImagePath(dto.answerImagePath),
                    easeFactor: dto.easeFactor,
                    interval: dto.interval,
                    repetitions: dto.repetitions
                )
                model.categoryValues = dto.categoryValueIds.compactMap { valuesById[$0] }
                archive.insert(model)
            }

            // 4. 单次 saveContext：删除+插入在同一个事务中原子提交。
            //    失败时 rollbackContext() 同时撤销删除和插入，旧数据完整保留。
            try archive.saveContext()

            // 5. 旧图片必须保留到协调器确认 ZIP 图片全部恢复成功。
            return Set(oldImagePaths)

        } catch {
            // rollback 撤销所有未提交变更（包括删除和插入），旧数据完整保留
            archive.rollbackContext()
            SnapDrillLogger.data.error("恢复失败，数据已回滚")
            throw error
        }
    }

    /// 删除已不被恢复后资料库引用的旧图片。
    public func deleteImages(paths: Set<String>) async {
        for path in paths {
            try? await imageStorage.deleteImage(path: path)
        }
    }

    // MARK: - Private Helpers

    private func sanitizedImagePath(_ path: String?) -> String? {
        guard let path else { return nil }
        guard ImageStorage.isSafeRelativeImagePath(path) else {
            SnapDrillLogger.data.warning("恢复时忽略非法图片路径: \(path)")
            return nil
        }
        return path
    }

    /// 纯内存操作：标记所有分类数据待删除，不 save。
    private func deleteAllTaxonomyInMemory() throws {
        // L3 动态维度系统：先删值再删维度
        try categoryValue.deleteAll()
        try dimension.deleteAll()
    }
}

// MARK: - Preview Support

/// 预览专用数据仓库容器（使用内存 ModelContainer）
public final class PreviewRepositoryContainer {
    private let executor: DataExecutor

    /// 归档资料仓库
    public let archive: ArchiveRepository
    /// 分类维度仓库（L3）
    public let dimension: CategoryDimensionRepository
    /// 维度值仓库（L3）
    public let categoryValue: CategoryValueRepository

    /// 创建内存预览容器
    public init() {
        let executor = DataExecutor(inMemory: true)
        self.executor = executor

        self.archive = ArchiveRepository(executor: executor)
        self.dimension = CategoryDimensionRepository(executor: executor)
        self.categoryValue = CategoryValueRepository(executor: executor)
    }
}
