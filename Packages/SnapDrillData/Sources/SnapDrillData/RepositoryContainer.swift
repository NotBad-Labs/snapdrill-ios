//
//  RepositoryContainer.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义数据层仓库容器协议及默认/预览实现，作为 Features 层访问持久化的统一入口。
//

import Foundation
import SwiftData
import SnapDrillDomain

// MARK: - Repository 容器协议

/// 数据层仓库容器协议
/// 集中提供各领域层仓库的实现。
@MainActor
public protocol RepositoryContainer: Sendable {
    var review: ReviewRepositoryProtocol { get }
    var subject: SubjectRepositoryProtocol { get }
    var source: SourceRepositoryProtocol { get }
    var tag: TagRepositoryProtocol { get }
    var grade: GradeRepositoryProtocol { get }
}

// MARK: - Default Implementation

/// 默认数据仓库容器
@MainActor
public final class DefaultRepositoryContainer: RepositoryContainer {
    public let review: ReviewRepositoryProtocol
    public let subject: SubjectRepositoryProtocol
    public let source: SourceRepositoryProtocol
    public let tag: TagRepositoryProtocol
    public let grade: GradeRepositoryProtocol

    // MARK: - Initialization

    public init(modelContext: ModelContext = PersistenceController.shared.container.mainContext) {
        self.review = ReviewRepository(modelContext: modelContext)
        self.subject = SubjectRepository(modelContext: modelContext)
        self.source = SourceRepository(modelContext: modelContext)
        self.tag = TagRepository(modelContext: modelContext)
        self.grade = GradeRepository(modelContext: modelContext)
    }
}

// MARK: - Preview Support

/// 预览专用数据仓库容器
@MainActor
public final class PreviewRepositoryContainer: RepositoryContainer {
    public let review: ReviewRepositoryProtocol
    public let subject: SubjectRepositoryProtocol
    public let source: SourceRepositoryProtocol
    public let tag: TagRepositoryProtocol
    public let grade: GradeRepositoryProtocol

    public init() {
        // 创建内存中的 ModelContext
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

