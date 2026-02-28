//
//  Tag.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义用户自定义标签领域实体。
//

import Foundation

/// 标签领域实体
public struct Tag: Sendable, Identifiable, Codable {
    public let id: UUID
    public var name: String
    public var colorHex: String
    
    public init(
        id: UUID = UUID(),
        name: String,
        colorHex: String = "#CCCCCC"
    ) {
        self.id = id
        self.name = name
        self.colorHex = colorHex
    }
}
