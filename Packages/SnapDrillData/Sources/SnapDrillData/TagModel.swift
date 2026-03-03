//
//  TagModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  标签数据模型 (SwiftData)，支持多对多关联。
//

import Foundation
import SwiftData

/// 标签模型
@Model
public final class TagModel {

    // MARK: - Properties

    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#8E8E93"
    public var createdAt: Date = Date()

    // Relationship
    @Relationship(deleteRule: .nullify)
    public var items: [ReviewItemModel]? = []

    // MARK: - Initialization

    public init(name: String, colorHex: String = "#8E8E93") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }

}
