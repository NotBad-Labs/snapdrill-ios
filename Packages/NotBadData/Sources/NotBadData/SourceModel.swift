//
//  SourceModel.swift
//  NotBadData
//
//  Created by NotBad Architect on 2026/01/01.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  来源数据模型 (Source)，例如：试卷、作业、教材等。
//

import SwiftData
import Foundation

@Model
public final class SourceModel {
    /// 来源名称 (Unique)
    @Attribute(.unique) public var name: String
    
    /// 图标名称 (SF Symbol)
    public var icon: String
    
    /// 颜色 Hex
    public var colorHex: String
    
    /// 排序权重 (越小越靠前)
    public var sortOrder: Int
    
    public init(name: String, icon: String = "doc.text", colorHex: String = "#808080", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
