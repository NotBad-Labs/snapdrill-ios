//
//  ReviewRating.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  SM-2 算法复习评分等级枚举。
//

import Foundation

/// 复习评分等级（SM-2 标准等级）
///
/// SM-2 算法使用 0-5 的评分，此处简化为四级：
/// - `again` (0): 完全忘记
/// - `hard` (2): 记得但很吃力
/// - `good` (3): 记得但有些犹豫
/// - `easy` (5): 非常容易记住
public enum ReviewRating: Int {
    case again = 0  // 忘记了
    case hard = 2   // 很难
    case good = 3   // 还行
    case easy = 5   // 简单
}
