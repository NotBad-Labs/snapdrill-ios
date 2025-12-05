//
//  RepositoryError.swift
//  NotBad
//
//  Data Layer - 数据仓库错误类型
//

import Foundation

// MARK: - RepositoryError

/// Repository 层错误
///
/// 表示数据操作失败，封装底层存储错误。
///
/// ## 使用场景
///
/// - 数据库读写失败
/// - 查询失败
/// - 事务失败
///
/// ## 使用示例
///
/// ```swift
/// do {
///     try modelContext.save()
/// } catch {
///     throw RepositoryError.saveFailed(underlying: error)
/// }
/// ```
enum RepositoryError: Error, LocalizedError, Sendable {
    
    // MARK: - CRUD Errors
    
    /// 保存失败
    case saveFailed(underlying: Error)
    
    /// 删除失败
    case deleteFailed(underlying: Error)
    
    /// 查询失败
    case fetchFailed(underlying: Error)
    
    /// 实体不存在
    case notFound(id: UUID)
    
    /// 批量操作部分失败
    case partialFailure(succeeded: Int, failed: Int, errors: [Error])
    
    // MARK: - Transaction Errors
    
    /// 事务失败
    case transactionFailed(underlying: Error)
    
    /// 事务回滚
    case transactionRolledBack(reason: String)
    
    // MARK: - Migration Errors
    
    /// 迁移失败
    case migrationFailed(fromVersion: String, toVersion: String, underlying: Error)
    
    /// 数据损坏
    case dataCorrupted(reason: String)
    
    // MARK: - Constraint Errors
    
    /// 唯一约束冲突
    case uniqueConstraintViolation(field: String, value: String)
    
    /// 外键约束冲突
    case foreignKeyViolation(relation: String)
    
    // MARK: - LocalizedError
    
    var errorDescription: String? {
        switch self {
        case .saveFailed:
            return String(localized: "保存失败，请重试")
            
        case .deleteFailed:
            return String(localized: "删除失败，请重试")
            
        case .fetchFailed:
            return String(localized: "加载数据失败")
            
        case .notFound:
            return String(localized: "数据不存在或已被删除")
            
        case .partialFailure(let succeeded, let failed, _):
            return String(localized: "部分操作失败：成功 \(succeeded) 项，失败 \(failed) 项")
            
        case .transactionFailed:
            return String(localized: "操作失败，请重试")
            
        case .transactionRolledBack(let reason):
            return String(localized: "操作已回滚：\(reason)")
            
        case .migrationFailed(let from, let to, _):
            return String(localized: "数据迁移失败（\(from) → \(to)），请联系支持")
            
        case .dataCorrupted(let reason):
            return String(localized: "数据损坏：\(reason)")
            
        case .uniqueConstraintViolation(let field, _):
            return String(localized: "\(field)已存在")
            
        case .foreignKeyViolation(let relation):
            return String(localized: "关联的\(relation)不存在")
        }
    }
    
    // MARK: - Underlying Error
    
    /// 获取底层错误
    var underlyingError: Error? {
        switch self {
        case .saveFailed(let error),
             .deleteFailed(let error),
             .fetchFailed(let error),
             .transactionFailed(let error),
             .migrationFailed(_, _, let error):
            return error
        default:
            return nil
        }
    }
}
