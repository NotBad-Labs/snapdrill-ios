//
//  TestHelpers.swift
//  NotBadDataTests
//
//  Created by Antigravity AI on 2026/01/02.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  测试辅助工具和 Mock 对象
//

import Foundation
import SwiftData
@testable import NotBadData
@testable import NotBadCore

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

// MARK: - Test Container Helper

@MainActor
class TestModelContainer {
    static func create() throws -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(
            for: ReviewItemModel.self,
                 SubjectModel.self,
                 SourceModel.self,
                 TagModel.self,
            configurations: config
        )
    }
}
