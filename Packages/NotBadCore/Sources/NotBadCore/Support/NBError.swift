//
//  NBError.swift
//  NotBadSupport
//
//  Created by NotBad Labs on 2025/12/30.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  定义全应用通用的错误类型 (NotBadError)。
//

import Foundation

/// 通用应用错误类型
public enum NBError: LocalizedError {
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
