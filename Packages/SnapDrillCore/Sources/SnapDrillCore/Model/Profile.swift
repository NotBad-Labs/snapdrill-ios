//
//  Profile.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学习者 Profile 数据模型（纯值类型，JSON 持久化）。
//

import Foundation

/// 学习者 Profile
///
/// 每个 Profile 对应一个独立的数据库和图片目录（Vault 模式）。
/// 存储在 `Documents/profiles.json` 中，不使用 SwiftData。
nonisolated public struct Profile: Codable, Identifiable, Sendable, Equatable {
    /// Profile 唯一标识符（同时作为目录名）
    public let id: UUID
    /// 学习者名称（如"小明"）
    public var name: String
    /// 头像（SF Symbol 名称或本地图片路径）
    public var avatar: String
    /// 头像颜色索引 (0-5)
    public var avatarColorIndex: Int
    /// 创建时间
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        avatar: String = "person.crop.circle.fill",
        avatarColorIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.avatarColorIndex = avatarColorIndex
        self.createdAt = createdAt
    }
}
