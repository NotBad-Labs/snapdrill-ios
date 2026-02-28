//
//  DomainError.swift
//  SnapDrillDomain
//
//  Created by NotBad Labs on 2026/02/28.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义领域层统一错误类型。
//

import Foundation

/// 领域层错误类型
///
/// 继承 `LocalizedError` 以提供用户友好的错误信息。
public enum DomainError: Error, LocalizedError {
    /// 实体被引用，无法删除
    case entityInUse(entityName: String)
    /// 题目文字和图片不能同时为空
    case invalidContent

    public var errorDescription: String? {
        switch self {
        case .entityInUse(let name):
            return "无法删除「\(name)」，因为它正在被使用。"
        case .invalidContent:
            return "题目文字和图片至少需要填写一项。"
        }
    }
}
