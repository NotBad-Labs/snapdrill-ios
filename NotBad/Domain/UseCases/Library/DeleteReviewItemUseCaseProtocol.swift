//
//  DeleteReviewItemUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - DeleteReviewItemUseCaseProtocol

/// 删除错题用例协议
///
/// 负责删除错题记录：
/// - 支持单个删除
/// - 支持批量删除
/// - 支持撤销（可选）
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeDeleteReviewItemUseCase()
/// try await useCase.execute(itemId: item.id)
/// ```
@MainActor
protocol DeleteReviewItemUseCaseProtocol: Sendable {
    
    /// 删除单个错题
    ///
    /// - Parameter itemId: 题目 ID
    /// - Throws: 删除失败时抛出错误
    func execute(itemId: UUID) async throws
    
    /// 批量删除错题
    ///
    /// - Parameter itemIds: 题目 ID 列表
    /// - Throws: 删除失败时抛出错误
    func execute(itemIds: [UUID]) async throws
    
    /// 删除指定学科的所有错题
    ///
    /// - Parameter subject: 学科
    /// - Returns: 删除的数量
    /// - Throws: 删除失败时抛出错误
    @discardableResult
    func execute(subject: Subject) async throws -> Int
    
    /// 删除所有已掌握的错题
    ///
    /// - Returns: 删除的数量
    /// - Throws: 删除失败时抛出错误
    @discardableResult
    func executeMastered() async throws -> Int
}
