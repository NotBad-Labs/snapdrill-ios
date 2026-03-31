//
//  DataError.swift
//  SnapDrillData
//
//  Created by NotBad Labs on 2026/01/02.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  数据层错误定义
//

import Foundation
import SnapDrillCore

/// 数据层操作错误
///
/// 定义所有数据访问和操作可能产生的错误类型。
public enum DataError: LocalizedError {

    // MARK: - Cases

    /// 尝试创建重复名称的实体
    case duplicateName(name: String, entityType: String)

    // MARK: - Computed Properties

    public var errorDescription: String? {
        switch self {
        case .duplicateName(let name, let type):
            return L10n.DataErrors.duplicateName(name, type)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .duplicateName:
            return L10n.DataErrors.recoverySuggestionDuplicate
        }
    }
}
