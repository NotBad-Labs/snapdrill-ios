//
//  ProfileError.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation

/// Profile 操作错误。
public enum ProfileError: LocalizedError {
    case cannotDeleteLastProfile
    /// 有进行中的操作，无法切换 Profile。
    case switchBlocked(reason: String)

    public var errorDescription: String? {
        switch self {
        case .cannotDeleteLastProfile:
            return "无法删除最后一个学习者"
        case .switchBlocked(let reason):
            return "无法切换：\(reason)"
        }
    }
}
