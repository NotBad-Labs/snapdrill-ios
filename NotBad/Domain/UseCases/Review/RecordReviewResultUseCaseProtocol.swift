//
//  RecordReviewResultUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - RecordReviewResultUseCaseProtocol

/// 记录复习结果用例协议
///
/// 负责记录单题复习结果并更新题目状态：
/// - 更新掌握程度
/// - 计算下次复习时间（间隔重复算法）
/// - 更新复习次数
///
/// ## 间隔重复算法
///
/// 基于 SM-2 算法的简化版本：
/// - 答对：间隔 × 2.5（最长 30 天）
/// - 答错：间隔重置为 1 天
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeRecordReviewResultUseCase()
/// try await useCase.execute(
///     itemId: item.id,
///     isCorrect: true,
///     duration: 45.0
/// )
/// ```
@MainActor
protocol RecordReviewResultUseCaseProtocol: Sendable {
    
    /// 记录复习结果
    ///
    /// - Parameters:
    ///   - itemId: 题目 ID
    ///   - isCorrect: 是否正确
    ///   - duration: 用时（秒）
    /// - Returns: 更新后的题目
    /// - Throws: 记录失败时抛出错误
    @discardableResult
    func execute(
        itemId: UUID,
        isCorrect: Bool,
        duration: TimeInterval
    ) async throws -> ReviewItem
    
    /// 批量记录复习结果
    ///
    /// - Parameter results: 复习结果列表
    /// - Throws: 记录失败时抛出错误
    func execute(results: [ReviewResult]) async throws
}
