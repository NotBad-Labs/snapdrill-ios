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
    public let review: ReviewRepository
    public let subject: SubjectRepository
    public let source: SourceRepository
    public let tag: TagRepository
    public let grade: GradeRepository

    // MARK: - Initialization

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
    public let review: ReviewRepository
    public let subject: SubjectRepository
    public let source: SourceRepository
    public let tag: TagRepository
    public let grade: GradeRepository

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
