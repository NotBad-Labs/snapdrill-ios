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
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0
    ) -> ReviewItemModel {
        ReviewItemModel(
            id: id,
            content: content,
            imagePath: imagePath,
            easeFactor: easeFactor,
            interval: interval,
            repetitions: repetitions
        )
    }
}

// MARK: - Category Mocks (L3 动态维度)

extension CategoryDimensionModel {
    static func mock(
        name: String = "学科",
        isMultiValue: Bool = false,
        isBuiltIn: Bool = true,
        systemKey: String? = CategorySystemKey.subject,
        sortOrder: Int = 0,
        icon: String = "book"
    ) -> CategoryDimensionModel {
        CategoryDimensionModel(
            name: name, isMultiValue: isMultiValue, isBuiltIn: isBuiltIn,
            systemKey: systemKey, sortOrder: sortOrder, icon: icon
        )
    }
}

extension CategoryValueModel {
    static func mock(
        name: String = "数学",
        icon: String = "function",
        colorHex: String = "#FF0000",
        sortOrder: Int = 0,
        dimension: CategoryDimensionModel? = nil
    ) -> CategoryValueModel {
        CategoryValueModel(
            name: name, icon: icon, colorHex: colorHex,
            sortOrder: sortOrder, dimension: dimension
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
