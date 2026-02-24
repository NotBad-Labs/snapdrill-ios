//
//  TagModel.swift
//  NotBadData
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  标签数据模型 (SwiftData)，支持多对多关联。
//

import Foundation
import SwiftData

/// 标签模型
///
/// 用于对题目进行多维度的标记，如：因为粗心、因为计算错误、期中考、压轴题等。
@Model
public final class TagModel {
    public var id: UUID = UUID()
    public var name: String = ""
    public var colorHex: String = "#8E8E93"
    public var createdAt: Date = Date()
    
    // Relationship
    @Relationship(deleteRule: .nullify)
    public var items: [ReviewItemModel]? = []
    
    public init(id: UUID = UUID(), name: String, colorHex: String = "#8E8E93") {
        self.id = id
        self.name = name
        self.colorHex = colorHex
        self.createdAt = Date()
    }
}
