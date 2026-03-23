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

    /// 尝试创建重复的实体
    case duplicateItem(id: UUID)

    /// 尝试创建重复名称的实体
    case duplicateName(name: String, entityType: String)

    /// 实体不存在
    case notFound(id: UUID, entityType: String)

    /// 无效的数据状态
    case invalidState(reason: String)

    /// 数据库操作失败
    case databaseError(underlying: Error)

    /// 数据验证失败
    case validationFailed(field: String, reason: String)

    // MARK: - Computed Properties

    public var errorDescription: String? {
        switch self {
        case .duplicateItem(let id):
            return L10n.DataErrors.duplicateItem(String(id.uuidString.prefix(8)) + "...")
        case .duplicateName(let name, let type):
            return L10n.DataErrors.duplicateName(name, type)
        case .notFound(let id, let type):
            return L10n.DataErrors.notFound(type, String(id.uuidString.prefix(8)) + "...")
        case .invalidState(let reason):
            return L10n.DataErrors.invalidState(reason)
        case .databaseError(let error):
            return L10n.DataErrors.databaseError(error.localizedDescription)
        case .validationFailed(let field, let reason):
            return L10n.DataErrors.validationFailed(field, reason)
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .duplicateItem, .duplicateName:
            return L10n.DataErrors.recoverySuggestionDuplicate
        case .notFound:
            return L10n.DataErrors.recoverySuggestionNotFound
        case .invalidState:
            return L10n.DataErrors.recoverySuggestionInvalidState
        case .databaseError:
            return L10n.DataErrors.recoverySuggestionDatabase
        case .validationFailed:
            return L10n.DataErrors.recoverySuggestionValidation
        }
    }
}
