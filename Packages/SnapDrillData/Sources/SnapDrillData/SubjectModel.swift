//
//  SubjectModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学科数据模型 (SwiftData)，如数学、英语等。
//

import Foundation
import SwiftData

/// 学科数据模型
@Model
public final class SubjectModel {

    // MARK: - Properties

    /// 唯一标识
    public var id: UUID = UUID()

    /// 学科名称 (e.g. "Math", "语文")
    public var name: String = ""

    /// 图标名称 (SF Symbol)
    public var icon: String = "book"

    /// 颜色名称 (Hex or System Color Name)
    public var colorHex: String = "#808080"

    /// 排序权重 (越小越靠前)
    public var sortOrder: Int = 0

    // MARK: - Initialization

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        colorHex: String,
        sortOrder: Int
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }

}
