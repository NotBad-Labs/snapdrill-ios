//
//  SystemDomainError.swift
//  NotBad
//
//  Created by YIMING LIAO on 7/19/25.
//

import Foundation

/// 系统领域错误
/// 定义了所有与系统通用操作相关的业务逻辑错误，例如无效的版本格式、无效的时间范围等。
/// 遵循 `DomainError` 协议，以便提供统一的错误描述和本地化支持。
enum SystemDomainError: DomainError {
    // MARK: - 版本管理错误
    case invalidVersionFormat(String) // 无效的版本号格式，包含具体原因

    // MARK: - 时间/日期相关错误
    case invalidTimeRange(String) // 无效的时间范围，包含具体原因（如开始时间晚于结束时间）
    case invalidDatePeriod(String) // 无效的日期周期，包含具体原因

    // MARK: - 文件系统/IO 错误
    case fileNotFound(String) // 文件未找到，包含文件路径或名称
    case fileReadFailed(String) // 文件读取失败，包含具体原因
    case fileWriteFailed(String) // 文件写入失败，包含具体原因
    case directoryCreationFailed(String) // 目录创建失败

    // MARK: - 配置相关错误
    case configurationLoadFailed(String) // 配置加载失败，包含具体原因
    case invalidConfiguration(String) // 配置无效或不完整

    // MARK: - 通用系统错误
    case genericSystemError(String) // 通用系统错误，包含具体消息

    // MARK: - CustomStringConvertible 协议实现
    /// 提供错误的字符串描述，用于日志或调试。
    var description: String {
        switch self {
        case .invalidVersionFormat(let versionString):
            return "版本号格式 '\(versionString)' 无效，应为 'X.Y.Z' 或 'X.Y.Z (Build)' 形式。"
        case .invalidTimeRange(let reason):
            return "时间范围无效: \(reason)。"
        case .invalidDatePeriod(let reason):
            return "日期周期无效: \(reason)。"
        case .fileNotFound(let path):
            return "文件未找到: '\(path)'。"
        case .fileReadFailed(let reason):
            return "文件读取失败: \(reason)。"
        case .fileWriteFailed(let reason):
            return "文件写入失败: \(reason)。"
        case .directoryCreationFailed(let path):
            return "目录创建失败: '\(path)'。"
        case .configurationLoadFailed(let reason):
            return "配置加载失败: \(reason)。"
        case .invalidConfiguration(let reason):
            return "配置无效: \(reason)。"
        case .genericSystemError(let message):
            return "发生通用系统错误: \(message)。"
        }
    }

    // MARK: - LocalizedError 协议实现
    /// 提供错误的本地化描述，用于向用户展示。
    var errorDescription: String? {
        // 在实际应用中，这里会通过本地化字符串表获取对应的本地化消息。
        return description // 暂时直接返回 description
    }
}

// MARK: - 辅助协议 (为了编译，实际应从其他文件导入)
// 这些协议在实际项目中应有自己的文件，这里仅为编译目的提供简化定义。

/// 领域错误基础协议 (简化版)
protocol DomainError: Error, CustomStringConvertible, LocalizedError { }

