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
/// - 更新复习次数
@MainActor
final class RecordReviewResultUseCase: RecordReviewResultUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
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
        // 1. 查找题目
        guard let item = repository.fetchAll().first(where: { $0.id == itemId }) else {
            throw RecordReviewResultError.itemNotFound(id: itemId)
        }
        
        // 2. 计算新的掌握程度
        let currentMastery = MasteryLevel(rawValue: item.masteryLevel) ?? MasteryLevel.none
        let newMastery = calculateNewMastery(current: currentMastery, isCorrect: isCorrect)
        
        // 3. 计算下次复习时间
        let nextReviewDate = calculateNextReviewDate(
            mastery: newMastery,
            isCorrect: isCorrect,
            currentInterval: item.reviewInterval.intervalDays
        )
        
        // 4. 更新题目
        let updatedItem = ReviewItem(
            id: item.id,
            imageData: item.imageData,
            title: item.title,
            note: item.note,
            createdAt: item.createdAt,
            updatedAt: Date(),
            masteryLevel: newMastery.rawValue,
            nextReviewDate: nextReviewDate,
            reviewCount: item.reviewCount + 1,
            subjectRaw: item.subjectRaw,
            gradeRaw: item.gradeRaw,
            knowledgePointsRaw: item.knowledgePointsRaw,
            difficultyRaw: item.difficultyRaw,
            errorTypeRaw: item.errorTypeRaw,
            sourceRaw: item.sourceRaw,
            reviewItemTypeRaw: item.reviewItemTypeRaw,
            isFavorite: item.isFavorite
        )
        
        // 5. 保存
        do {
            try repository.save(updatedItem)
        } catch {
            throw RecordReviewResultError.saveFailed(underlying: error)
        }
        
        return updatedItem
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
    
    /// 计算新的掌握程度
    private func calculateNewMastery(current: MasteryLevel, isCorrect: Bool) -> MasteryLevel {
        if isCorrect {
            // 答对：提升一级
            switch current {
            case .none: return .glimpse
            case .glimpse: return .partial
            case .partial: return .good
            case .good: return .mastered
            case .mastered: return .mastered
            }
        } else {
            // 答错：降低一级（最低到 glimpse）
            switch current {
            case .none: return .none
            case .glimpse: return .none
            case .partial: return .glimpse
            case .good: return .partial
            case .mastered: return .good
            }
        }
    }
    
    /// 计算下次复习时间（SM-2 简化版）
    private func calculateNextReviewDate(
        mastery: MasteryLevel,
        isCorrect: Bool,
        currentInterval: Int
    ) -> Date {
        let calendar = Calendar.current
        let today = Date()
        
        let intervalDays: Int
        if isCorrect {
            // 答对：间隔 × 2.5（最长 30 天）
            let multiplier = 2.5
            intervalDays = min(30, max(1, Int(Double(currentInterval) * multiplier)))
        } else {
            // 答错：间隔重置为 1 天
            intervalDays = 1
        }
        
        return calendar.date(byAdding: .day, value: intervalDays, to: today) ?? today
    }
}

// MARK: - RecordReviewResultError

/// 记录复习结果错误
enum RecordReviewResultError: LocalizedError {
    case itemNotFound(id: UUID)
    case saveFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .itemNotFound(let id):
            return "找不到题目 (ID: \(id))"
        case .saveFailed(let error):
            return "保存失败: \(error.localizedDescription)"
        }
    }
}
