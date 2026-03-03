//
//  RepositoryContainer.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据层仓库容器，作为 Features 层访问持久化的统一入口。
//

import Foundation
import SwiftData

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

    /// 删除所有复习数据与分类数据
    public func deleteAllData() throws {
        try review.deleteAll()
        try deleteAllTaxonomy()
    }

    /// 删除所有分类数据（学科、来源、标签、年级）
    public func deleteAllTaxonomy() throws {
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
