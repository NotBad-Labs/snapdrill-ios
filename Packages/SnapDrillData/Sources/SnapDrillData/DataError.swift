//
//  DataError.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/01/02.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  数据层错误定义
//

import Foundation

/// 数据层操作错误
///
/// 定义所有数据访问和操作可能产生的错误类型。
public enum DataError: LocalizedError {
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
    
    public var errorDescription: String? {
        switch self {
        case .duplicateItem(let id):
            return "该项目已存在 (ID: \(id.uuidString.prefix(8))...)"
        case .duplicateName(let name, let type):
            return "\(type) '\(name)' 已存在"
        case .notFound(let id, let type):
            return "\(type) 不存在 (ID: \(id.uuidString.prefix(8))...)"
        case .invalidState(let reason):
            return "数据状态无效: \(reason)"
        case .databaseError(let error):
            return "数据库操作失败: \(error.localizedDescription)"
        case .validationFailed(let field, let reason):
            return "字段 '\(field)' 验证失败: \(reason)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .duplicateItem, .duplicateName:
            return "请使用不同的名称或检查是否已存在相同项目"
        case .notFound:
            return "请刷新列表或检查项目是否已被删除"
        case .invalidState:
            return "请重新加载数据或联系技术支持"
        case .databaseError:
            return "请重试操作，如果问题持续请重启应用"
        case .validationFailed:
            return "请检查输入内容是否符合要求"
        }
    }
}
