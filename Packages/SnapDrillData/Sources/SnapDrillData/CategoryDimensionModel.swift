//
//  CategoryDimensionModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度（命名维度型）：学科 / 来源 / 年级 / 标签 / 用户自定义。
//  有序刻度型「难度」不在此系统内，仍是 ReviewItemModel.difficulty: Int。
//

import Foundation
import SwiftData

/// 分类维度模型
///
/// 一个「维度」是一类分类（如学科、来源、章节）。内置维度（学科/来源/年级/标签）
/// 用稳定 `systemKey` 识别、不可删除；用户可新建任意维度。
/// 每个维度通过 `isMultiValue` 决定一题在该维度下可贴一个值（单值）还是多个值（多值）。
@Model
public final class CategoryDimensionModel {

    // MARK: - Properties

    /// 唯一标识
    public var id: UUID = UUID()

    /// 维度显示名（用户自定义维度用它展示；内置维度按 systemKey 走本地化）
    public var name: String = ""

    /// 单值 vs 多值：false=一题一个值（学科/来源/年级）；true=一题多个值（标签/错因）
    public var isMultiValue: Bool = false

    /// 是否内置维度（内置不可删除、改名受限）
    public var isBuiltIn: Bool = false

    /// 稳定语义键：内置维度用它做代码识别与幂等 seed（如 "subject"/"source"/"grade"/"tag"），
    /// 用户自定义维度为 nil。
    ///
    /// 不用 name/UUID 识别——name 可改、每次 seed 的 UUID 不同（CloudKit 同步后会撞成两份）。
    public var systemKey: String?

    /// 维度排序权重（越小越靠前，决定录入页 section / 导出列顺序）
    public var sortOrder: Int = 0

    /// 维度级图标（SF Symbol，用于管理界面）
    public var icon: String = "tag"

    /// 该维度下的所有值（一对多）。inverse 声明在本侧，指向 `CategoryValueModel.dimension`（对端裸关系）。
    @Relationship(deleteRule: .cascade, inverse: \CategoryValueModel.dimension)
    public var values: [CategoryValueModel]? = []

    // MARK: - Initialization

    /// 创建分类维度（全参数带默认值——SwiftData 类型推断 + CloudKit 兼容硬要求）
    public init(
        id: UUID = UUID(),
        name: String = "",
        isMultiValue: Bool = false,
        isBuiltIn: Bool = false,
        systemKey: String? = nil,
        sortOrder: Int = 0,
        icon: String = "tag"
    ) {
        self.id = id
        self.name = name
        self.isMultiValue = isMultiValue
        self.isBuiltIn = isBuiltIn
        self.systemKey = systemKey
        self.sortOrder = sortOrder
        self.icon = icon
    }
}
