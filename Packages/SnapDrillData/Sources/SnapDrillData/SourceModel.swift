//
//  SourceModel.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/01/01.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  来源数据模型 (Source)，例如：试卷、作业、教材等。
//

import SwiftData
import Foundation

@Model
public final class SourceModel {
    
    // MARK: - Properties
    
    /// 来源名称
    public var name: String = ""
    
    /// 图标名称 (SF Symbol)
    public var icon: String = "doc.text"
    
    /// 颜色 Hex
    public var colorHex: String = "#808080"
    
    /// 排序权重 (越小越靠前)
    public var sortOrder: Int = 0
    
    // MARK: - Initialization
    
    public init(name: String, icon: String = "doc.text", colorHex: String = "#808080", sortOrder: Int = 0) {
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}
