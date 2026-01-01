//
//  SubjectModel.swift
//  NotBadData
//
//  Created by Yiming Liao on 2025/12/30.
//  Copyright © 2025 NotBad Team. All rights reserved.
//
//  学科数据模型 (SwiftData)，如数学、英语等。
//

import Foundation
import SwiftData

/// 学科数据模型
///
/// 用于支持用户自定义学科列表。
@Model
public final class SubjectModel {
    /// 唯一标识
    @Attribute(.unique) public var id: UUID
    
    /// 学科名称 (e.g. "Math", "语文")
    public var name: String
    
    /// 图标名称 (SF Symbol)
    public var icon: String
    
    /// 颜色名称 (Hex or System Color Name)
    public var colorHex: String
    
    /// 排序权重 (越小越靠前)
    public var sortOrder: Int
    
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
