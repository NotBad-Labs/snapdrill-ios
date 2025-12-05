//
//  RepositoryError+Conversion.swift
//  NotBad
//
//  Repository 错误到 Application 层错误的转换
//

import Foundation

// MARK: - RepositoryError → AppError 转换

extension RepositoryError {
    
    /// 将 Repository 错误转换为 AppError
    ///
    /// 用于在 Use Case 层将底层错误转换为用户友好的错误。
    ///
    /// ## 使用示例
    ///
    /// ```swift
    /// do {
    ///     try await repository.save(item)
    /// } catch let error as RepositoryError {
    ///     throw error.toAppError()
    /// }
    /// ```
    func toAppError() -> AppError {
        switch self {
        case .saveFailed:
            return .saveFailed(reason: self.errorDescription)
            
        case .deleteFailed:
            return .deleteFailed(reason: self.errorDescription)
            
        case .fetchFailed:
            return .loadFailed(reason: self.errorDescription)
            
        case .notFound:
            return .notFound
            
        case .partialFailure(let succeeded, let failed, _):
            return .saveFailed(reason: "部分操作失败：成功 \(succeeded) 项，失败 \(failed) 项")
            
        case .transactionFailed:
            return .saveFailed(reason: "事务失败，请重试")
            
        case .transactionRolledBack(let reason):
            return .saveFailed(reason: "操作已回滚：\(reason)")
            
        case .migrationFailed(let from, let to, _):
            return .loadFailed(reason: "数据迁移失败（\(from) → \(to)）")
            
        case .dataCorrupted(let reason):
            return .loadFailed(reason: "数据损坏：\(reason)")
            
        case .uniqueConstraintViolation(let field, _):
            return .saveFailed(reason: "\(field)已存在")
            
        case .foreignKeyViolation(let relation):
            return .saveFailed(reason: "关联的\(relation)不存在")
        }
    }
}

// MARK: - Error 便捷转换

extension Error {
    
    /// 将任意错误转换为 AppError
    ///
    /// 如果已经是 AppError，直接返回。
    /// 如果是 RepositoryError，转换后返回。
    /// 其他错误包装为通用错误。
    func toAppError() -> AppError {
        if let appError = self as? AppError {
            return appError
        }
        
        if let repoError = self as? RepositoryError {
            return repoError.toAppError()
        }
        
        // 其他未知错误
        return .saveFailed(reason: localizedDescription)
    }
}
