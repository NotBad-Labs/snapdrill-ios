//
//  SourceModel.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/01/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  来源数据模型 (Source)，例如：试卷、作业、教材等。
//

import SwiftData
import Foundation

/// 来源数据模型
///
/// 表示题目的来源类别（如试卷、作业、教材等），用于对题库进行分类管理。
/// 每个 `ReviewItemModel` 可关联一个来源名称。
@Model
public final class SourceModel {

    // MARK: - Properties
    
    /// 唯一标识
    public var id: UUID = UUID()
    
    /// 来源名称
    public var name: String = ""
    
    /// 图标名称 (SF Symbol)
    public var icon: String = "doc.text"
    
    /// 颜色 Hex
    public var colorHex: String = "#808080"
    
    /// 排序权重 (越小越靠前)
    public var sortOrder: Int = 0
    
    // MARK: - Initialization
    
    /// 创建来源模型
    /// - Parameters:
    ///   - id: 唯一标识，默认自动生成
    ///   - name: 来源名称，如 "试卷"
    ///   - icon: SF Symbol 图标名称，默认 `"doc.text"`
    ///   - colorHex: Hex 颜色字符串，默认 `"#808080"`
    ///   - sortOrder: 排序权重（越小越靠前），默认 0
    public init(id: UUID = UUID(), name: String, icon: String = "doc.text", colorHex: String = "#808080", sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
    
}
