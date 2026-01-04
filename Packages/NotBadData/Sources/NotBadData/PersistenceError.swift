//
//  PersistenceError.swift
//  NotBadData
//
//  Created by NotBad Architect on 2026/01/02.
//  Copyright © 2026 NotBad Team. All rights reserved.
//
//  持久化层错误定义
//

import Foundation

/// 持久化层错误
///
/// 定义 ModelContainer 初始化和持久化操作的错误类型。
public enum PersistenceError: LocalizedError {
    /// 无法创建 ModelContainer
    case containerInitializationFailed(underlying: Error)
    
    /// Schema 迁移失败
    case migrationFailed(from: String, to: String, underlying: Error)
    
    /// 存储不可用
    case storageUnavailable(reason: String)
    
    /// CloudKit 配置错误
    case cloudKitConfigurationError(underlying: Error)
    
    public var errorDescription: String? {
        switch self {
        case .containerInitializationFailed(let error):
            return "数据库初始化失败: \(error.localizedDescription)"
        case .migrationFailed(let from, let to, let error):
            return "数据迁移失败 (\(from) → \(to)): \(error.localizedDescription)"
        case .storageUnavailable(let reason):
            return "存储不可用: \(reason)"
        case .cloudKitConfigurationError(let error):
            return "iCloud 配置错误: \(error.localizedDescription)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .containerInitializationFailed:
            return "应用将使用临时存储，数据在重启后会丢失。请尝试重启应用。"
        case .migrationFailed:
            return "数据迁移失败，应用将使用临时存储。请联系技术支持。"
        case .storageUnavailable:
            return "请检查设备存储空间是否充足"
        case .cloudKitConfigurationError:
            return "请检查 iCloud 设置或在系统设置中登录 Apple ID"
        }
    }
}
