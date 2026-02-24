//
//  SnapDrillError.swift
//  SnapDrillCore
//
//  Created by SnapDrill Labs on 2025/12/30.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  定义全应用通用的错误类型。
//

import Foundation

/// 通用应用错误类型
public enum SnapDrillError: LocalizedError {
    case dataNotFound
    case captureFailed
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .dataNotFound:
            return "未找到请求的数据。"
        case .captureFailed:
            return "图像采集或识别失败。"
        case .unknown(let message):
            return "未知错误: \(message)"
        }
    }
}
