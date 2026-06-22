//
//  CategoryValueModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  维度值：某个维度下的一个可选项（如分类维度下的「题目」、标签维度下的「重点」）。
//

import Foundation
import SwiftData

/// 维度值模型
///
/// 属于某个 `CategoryDimensionModel`（多对一），可被多道题目引用（多对多）。
/// 改 `name` 后所有引用它的题目自动跟随（引用语义，无需级联改字段）。
@Model
public final class CategoryValueModel {

    // MARK: - Properties

    /// 唯一标识
    public var id: UUID = UUID()

    /// 值名称（"数学" / "试卷" / "高一" / "易错"）
    public var name: String = ""

    /// 图标（SF Symbol）
    public var icon: String = "circle"

    /// 颜色 Hex
    public var colorHex: String = "#808080"

    /// 同维度内排序权重（越小越靠前）
    public var sortOrder: Int = 0

    /// 创建时间（供标签维度按创建时间排序，保留旧 Tag 语义）
    public var createdAt: Date = Date()

    /// 所属维度（多对一）。inverse 在 `CategoryDimensionModel.values` 侧声明，本端裸关系。
    @Relationship(deleteRule: .nullify)
    public var dimension: CategoryDimensionModel?

    /// 引用本值的题目（多对多）。inverse 在 `ReviewItemModel.categoryValues` 侧声明，本端裸关系。
    @Relationship(deleteRule: .nullify)
    public var items: [ReviewItemModel]? = []

    // MARK: - Initialization

    /// 创建维度值（全参数带默认值）
    public init(
        id: UUID = UUID(),
        name: String = "",
        icon: String = "circle",
        colorHex: String = "#808080",
        sortOrder: Int = 0,
        createdAt: Date = Date(),
        dimension: CategoryDimensionModel? = nil
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.dimension = dimension
    }
}
