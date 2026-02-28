//
//  Difficulty.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义题目难度等级枚举（1-5 星），替代裸 Int 表示。
//

import Foundation

/// 题目难度等级（1-5 星）
///
/// 遵循 rawValue: Int 以支持 SwiftData 层的持久化桥接。
/// 禁止在业务代码中以裸 `Int` 代替此枚举。
public enum Difficulty: Int, CaseIterable, Sendable, Codable, Identifiable, Hashable {
    case one   = 1
    case two   = 2
    case three = 3
    case four  = 4
    case five  = 5

    /// 实现 Identifiable，以便直接用于 ForEach
    public var id: Int { rawValue }

    /// 星级数量（等同于 rawValue）
    public var starCount: Int { rawValue }
}
