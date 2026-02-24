//
//  Collection+Safe.swift
//  SnapDrillUtils
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  Collection 扩展，提供安全的数组下标访问。
//

import Foundation

public extension Collection {
    /// 安全下标访问
    ///
    /// 防止数组越界崩溃。如果索引无效，返回 nil。
    ///
    /// - Parameter index: 索引
    /// - Returns: 对应元素或 nil
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
