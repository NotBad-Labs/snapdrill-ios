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

    // MARK: - Unique Constraints

    /// 标签名称唯一约束（SchemaV4）
    #Unique<TagModel>([\.name])

    // MARK: - Properties

    /// 标签唯一标识符
    public var id: UUID = UUID()
    /// 标签名称
    public var name: String = ""
    /// 标签颜色（Hex 字符串，如 `"#8E8E93"`）
    public var colorHex: String = "#8E8E93"
    /// 创建时间
    public var createdAt: Date = Date()

    // 关联关系
    /// 关联的题目（Many-to-Many）
    @Relationship(deleteRule: .nullify)
    public var items: [ReviewItemModel]? = []

    // MARK: - Initialization

    /// 创建标签
    /// - Parameters:
    ///   - name: 标签名称
    ///   - colorHex: 标签颜色 Hex 字符串，默认灰色 `"#8E8E93"`
    public init(name: String, colorHex: String = "#8E8E93") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }

}
