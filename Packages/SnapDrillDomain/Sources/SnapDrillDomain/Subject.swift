//
//  Subject.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/27.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义学科领域实体及系统预设枚举。
//

import Foundation

/// 学科领域实体
///
/// 用户可在设置中增删改，系统提供默认预设值。
public struct Subject: Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "book",
        colorHex: String = "#808080",
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.sortOrder = sortOrder
    }
}

/// 学科预设值
///
/// 提供系统内置的常见学科，用于首次启动时初始化默认数据。
public enum SubjectPreset: String, CaseIterable, Identifiable {
    public var id: String { rawValue }

    case chinese     = "语文"
    case mathematics = "数学"
    case english     = "英语"
    case physics     = "物理"
    case chemistry   = "化学"
    case biology     = "生物"
    case history     = "历史"
    case geography   = "地理"
    case politics    = "政治"
    case other       = "其他"
}
