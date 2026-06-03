//
//  TestHelpers.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  测试辅助工具和 Mock 对象
//

import Foundation
import SwiftData
@testable import SnapDrillData
@testable import SnapDrillCore

// MARK: - ReviewItemModel Mock

extension ReviewItemModel {
    static func mock(
        id: UUID = UUID(),
        content: String = "Test content",
        imagePath: String? = nil,
        subject: String = "数学",
        source: String = "作业",
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0
    ) -> ReviewItemModel {
        ReviewItemModel(
            id: id,
            content: content,
            imagePath: imagePath,
            subject: subject,
            source: source,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions
        )
    }
}

// MARK: - SubjectModel Mock

extension SubjectModel {
    static func mock(
        name: String = "数学",
        icon: String = "function",
        colorHex: String = "#FF0000",
        sortOrder: Int = 0
    ) -> SubjectModel {
        SubjectModel(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder
        )
    }
}

// MARK: - SourceModel Mock

extension SourceModel {
    static func mock(
        name: String = "作业",
        icon: String = "doc.text",
        colorHex: String = "#0000FF",
        sortOrder: Int = 0
    ) -> SourceModel {
        SourceModel(
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: sortOrder
        )
    }
}

// MARK: - TagModel Mock

extension TagModel {
    static func mock(
        name: String = "重点",
        colorHex: String = "#00FF00"
    ) -> TagModel {
        TagModel(
            name: name,
            colorHex: colorHex
        )
    }
}

// MARK: - GradeModel Mock

extension GradeModel {
    static func mock(
        name: String = "高一",
        sortOrder: Int = 0
    ) -> GradeModel {
        GradeModel(
            name: name,
            sortOrder: sortOrder
        )
    }
}

// MARK: - Test Container Helper

/// 直接创建 in-memory ModelContainer，不经过 PersistenceController。
/// PersistenceController 在 defaultIsolation(MainActor) 下的同步 init
/// 会与 ModelContainer 内部 XPC 回调死锁（#599）。
/// 推荐使用 `DataExecutor(inMemory: true)` 替代（PR #8b）。
enum TestModelContainer {
    // 用 SnapDrillSchemaV1.models（含 CategoryDimension/Value）；S6 删旧模型后自动跟随
    nonisolated static let schema = Schema(SnapDrillSchemaV1.models)

    /// 直接创建 ModelContainer（向后兼容，旧测试使用）
    nonisolated static func create() throws -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

}
