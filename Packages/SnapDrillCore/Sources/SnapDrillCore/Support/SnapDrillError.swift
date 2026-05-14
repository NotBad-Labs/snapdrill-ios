//
//  SnapDrillError.swift
//  SnapDrillCore
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义全应用通用的错误类型。
//

import Foundation

/// 通用应用错误类型
public enum SnapDrillError: LocalizedError {
    
    // MARK: - Cases
    
    /// 数据未找到
    case dataNotFound
    /// 采集或识别过程失败
    case captureFailed
    /// 未知平台或逻辑错误
    case unknown(String)
    
    // MARK: - Computed Properties

    /// 本地化错误描述，用于 UI 展示
    public var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return L10n.Errors.dataNotFound
        case .captureFailed:
            return L10n.Errors.captureFailed
        case .unknown(let message):
            return L10n.Errors.unknownErrorWithMessage(message)
        }
    }
}
