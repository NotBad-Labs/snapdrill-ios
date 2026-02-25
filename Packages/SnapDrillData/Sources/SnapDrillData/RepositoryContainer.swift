//
//  RepositoryContainer.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation
import SwiftData

// MARK: - Repository 容器协议

/// 数据层仓库容器协议
///
/// 集中提供 SwiftData 持久化层的各个具体业务仓库的入口，
/// 代替在 ViewModel 或 View 中零散地 `new ReviewRepository(modelContext:)`。
@MainActor
public protocol RepositoryContainer: Sendable {
    var review: ReviewRepositoryProtocol { get }
    var subject: SubjectRepositoryProtocol { get }
    var source: SourceRepositoryProtocol { get }
    var tag: TagRepositoryProtocol { get }
}

// MARK: - Default Implementation

/// 默认数据仓库容器
///
/// 基于共享的 `PersistenceController.shared.container.mainContext`
/// 实例化真实的 SwiftData Repositories。
@MainActor
public final class DefaultRepositoryContainer: RepositoryContainer {
    public let review: ReviewRepositoryProtocol
    public let subject: SubjectRepositoryProtocol
    public let source: SourceRepositoryProtocol
    public let tag: TagRepositoryProtocol
    
    public init(modelContext: ModelContext = PersistenceController.shared.container.mainContext) {
        self.review = ReviewRepository(modelContext: modelContext)
        self.subject = SubjectRepository(modelContext: modelContext)
        self.source = SourceRepository(modelContext: modelContext)
        self.tag = TagRepository(modelContext: modelContext)
    }
}
