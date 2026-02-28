//
//  Grade.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义年级/学习阶段领域实体，与 Subject、Source 对等。
//

import Foundation

/// 年级/学习阶段领域实体
///
/// 代表题目所属的学习阶段（如：高一、初三）。
/// 用户可在设置中增删改，系统提供默认预设值。
public struct Grade: Sendable, Identifiable, Codable {
    /// 唯一标识符
    public let id: UUID
    /// 年级名称（如"高一"）
    public var name: String
    /// 排列顺序（用于 UI 展示）
    public var sortOrder: Int

    public init(
        id: UUID = UUID(),
        name: String,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
    }
}
