//
//  TestHelpers.swift
//  SnapDrillDataTests
//
//  Created by NotBad Labs on 2026/01/02.
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

class TestModelContainer {
    static func create() throws -> ModelContainer {
        // 使用 PersistenceController 而非直接 ModelContainer，
        // 包含 SnapDrillMigrationPlan 避免 CI 模拟器 schema 冲突。
        PersistenceController(inMemory: true).container
    }
}
