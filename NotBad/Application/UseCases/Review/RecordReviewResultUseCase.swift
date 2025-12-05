//
//  RecordReviewResultUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - RecordReviewResultUseCase

/// 记录复习结果用例实现
///
/// 实现 `RecordReviewResultUseCaseProtocol`，负责：
/// - 更新题目掌握程度
/// - 计算下次复习时间（间隔重复算法）
/// - 保存更新
@MainActor
final class RecordReviewResultUseCase: RecordReviewResultUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Constants
    
    /// 间隔重复算法参数
    private enum SpacedRepetition {
        /// 正确时的间隔倍数
        static let correctMultiplier: Double = 2.5
        /// 错误时重置的间隔（天）
        static let incorrectIntervalDays: Int = 1
        /// 最长间隔（天）
        static let maxIntervalDays: Int = 30
        /// 初始间隔（天）
        static let initialIntervalDays: Int = 1
    }
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - RecordReviewResultUseCaseProtocol
    
    @discardableResult
    func execute(
        itemId: UUID,
        isCorrect: Bool,
        duration: TimeInterval
    ) async throws -> ReviewItem {
        // 获取题目
        guard let item = repository.fetchAll().first(where: { $0.id == itemId }) else {
            throw RecordReviewResultError.itemNotFound(id: itemId)
        }
        
        // 更新复习状态
        updateReviewStatus(item: item, isCorrect: isCorrect)
        
        // 保存
        do {
            try repository.save(item)
            return item
        } catch {
            throw RecordReviewResultError.saveFailed(underlying: error)
        }
    }
    
    func execute(results: [ReviewResult]) async throws {
        for result in results {
            try await execute(
                itemId: result.itemId,
                isCorrect: result.isCorrect,
                duration: result.duration
            )
        }
    }
    
    // MARK: - Private Methods
    
    private func updateReviewStatus(item: ReviewItem, isCorrect: Bool) {
        // 更新复习次数
        item.reviewCount += 1
        
        // 更新掌握程度
        let currentLevel = MasteryLevel(rawValue: item.masteryLevel) ?? .notStarted
        let newLevel = calculateNewMasteryLevel(current: currentLevel, isCorrect: isCorrect)
        item.masteryLevel = newLevel.rawValue
        
        // 计算下次复习时间
        item.nextReviewDate = calculateNextReviewDate(
            currentLevel: currentLevel,
            newLevel: newLevel,
            isCorrect: isCorrect
        )
        
        // 更新时间
        item.updatedAt = Date()
    }
    
    /// 计算新的掌握程度
    private func calculateNewMasteryLevel(
        current: MasteryLevel,
        isCorrect: Bool
    ) -> MasteryLevel {
        if isCorrect {
            // 答对：提升一级
            return current.next ?? current
        } else {
            // 答错：降到"需复习"
            return .needsReview
        }
    }
    
    /// 计算下次复习时间
    private func calculateNextReviewDate(
        currentLevel: MasteryLevel,
        newLevel: MasteryLevel,
        isCorrect: Bool
    ) -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        if isCorrect {
            // 答对：根据当前间隔计算
            let currentInterval = intervalDays(for: currentLevel)
            var newInterval = Int(Double(currentInterval) * SpacedRepetition.correctMultiplier)
            newInterval = min(newInterval, SpacedRepetition.maxIntervalDays)
            return calendar.date(byAdding: .day, value: newInterval, to: now) ?? now
        } else {
            // 答错：重置为 1 天
            return calendar.date(
                byAdding: .day,
                value: SpacedRepetition.incorrectIntervalDays,
                to: now
            ) ?? now
        }
    }
    
    /// 获取掌握程度对应的复习间隔
    private func intervalDays(for level: MasteryLevel) -> Int {
        switch level {
        case .notStarted: return 1
        case .needsReview: return 1
        case .learning: return 2
        case .reviewing: return 4
        case .familiar: return 7
        case .mastered: return 14
        }
    }
}

// MARK: - RecordReviewResultError

/// 记录复习结果错误
enum RecordReviewResultError: Error, LocalizedError, Sendable {
    case itemNotFound(id: UUID)
    case saveFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return String(localized: "题目不存在")
        case .saveFailed:
            return String(localized: "保存失败，请重试")
        }
    }
}
