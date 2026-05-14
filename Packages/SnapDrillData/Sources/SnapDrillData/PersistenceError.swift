//
//  PersistenceError.swift
//  SnapDrillData
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  持久化层错误定义
//

import Foundation
import SnapDrillCore

/// 持久化层错误
///
/// 定义 ModelContainer 初始化和持久化操作的错误类型。
public enum PersistenceError: LocalizedError {

    // MARK: - Cases

    /// 无法创建 ModelContainer
    case containerInitializationFailed(underlying: Error)

    /// Schema 迁移失败
    case migrationFailed(from: String, to: String, underlying: Error)

    /// 存储不可用
    case storageUnavailable(reason: String)

    // MARK: - Computed Properties

    public var errorDescription: String? {
        switch self {
        case .containerInitializationFailed(let error):
            return L10n.PersistenceErrors.containerInitFailed + ": \(error.localizedDescription)"
        case .migrationFailed(let from, let to, let error):
            return L10n.PersistenceErrors.migrationFailed + " (\(from) → \(to)): \(error.localizedDescription)"
        case .storageUnavailable(let reason):
            return L10n.PersistenceErrors.storageUnavailable + ": \(reason)"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .containerInitializationFailed:
            return L10n.PersistenceErrors.recoveryContainerInit
        case .migrationFailed:
            return L10n.PersistenceErrors.recoveryMigration
        case .storageUnavailable:
            return L10n.PersistenceErrors.recoveryStorage
        }
    }
}
