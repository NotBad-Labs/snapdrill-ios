//
//  Collection+Safe.swift
//  NotBadUtils
//
//  Created by NotBad Architect.
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
