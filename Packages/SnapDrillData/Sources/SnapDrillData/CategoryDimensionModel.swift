//
//  CategoryDimensionModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度（命名维度型）：分类 / 来源 / 级别 / 标签 / 用户自定义。
//  有序刻度型「难度」不在此系统内，仍是 ReviewItemModel.difficulty: Int。
//

import Foundation
import SwiftData

/// 分类维度模型
///
/// 一个「维度」是一类分类（如分类、来源、章节）。内置维度（分类/来源/级别/标签）
/// 用稳定 `systemKey` 识别、不可删除；用户可新建任意维度。
/// 每个维度通过 `isMultiValue` 决定一题在该维度下可贴一个值（单值）还是多个值（多值）。
@Model
public final class CategoryDimensionModel {

    // MARK: - Properties

    /// 唯一标识
    public var id: UUID = UUID()

    /// 维度显示名（用户自定义维度用它展示；内置维度按 systemKey 走本地化）
    public var name: String = ""

    /// 单值 vs 多值：false=一项一个值（分类/来源/级别）；true=一项多个值（标签）
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
    /// 用 .nullify 全显式删除（删维度时 Repository 显式遍历删值 + 解题目引用），不靠 cascade——
    /// 本库走显式 save 路径，cascade 不可靠（FB13640004），"cascade + 手动遍历"是最差组合。
    @Relationship(deleteRule: .nullify, inverse: \CategoryValueModel.dimension)
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

// MARK: - 录入/编辑页可见性

extension CategoryDimensionModel {

    /// 可见性 key 的统一前缀（ProfileManager 据此做 per-Profile 搬运/清理；勿散写）。
    public static let visibilityKeyPrefix = "capture_dim_visible_"

    /// per-维度可见性的 UserDefaults key（录入页 / 编辑页 / 分类管理页共用的唯一契约）。
    /// 内置维度用稳定 `systemKey`、用户维度回退 `id`——集中一处避免多处重拼魔法串导致 desync。
    public var captureVisibilityKey: String {
        "\(Self.visibilityKeyPrefix)\(systemKey ?? id.uuidString)"
    }

    /// 采集页 / 管理页可见性的缺省值（仅当 UserDefaults 无显式设置时生效）：
    /// 用户自建维度默认可见；所有内置维度默认隐藏，保持首次录入极简并避免把通用资料归档
    /// 预先框进学习阶段场景。用户可在分类管理中按需打开内置维度。
    public var defaultCaptureVisibility: Bool {
        !isBuiltIn
    }
}
