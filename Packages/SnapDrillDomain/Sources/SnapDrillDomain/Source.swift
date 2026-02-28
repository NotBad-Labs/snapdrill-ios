//
//  Source.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义题目来源领域实体及系统预设枚举。
//

import Foundation

/// 题目来源领域实体
///
/// 用户可在设置中增删改，系统提供默认预设值。
public struct Source: Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var icon: String
    public var colorHex: String
    public var sortOrder: Int
    
    public init(
        id: UUID = UUID(),
        name: String,
        icon: String = "link",
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

/// 题目来源预设值
///
/// 提供系统内置的常见来源，用于首次启动时初始化默认数据。
public enum ReviewSourcePreset: String, CaseIterable, Identifiable {
    public var id: String { rawValue }

    case exam      = "试卷"
    case homework  = "作业"
    case textbook  = "教材"
    case wrongBook = "错题本"
    case other     = "其他"
}
