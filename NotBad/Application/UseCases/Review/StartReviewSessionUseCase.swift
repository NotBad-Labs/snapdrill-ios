//
//  StartReviewSessionUseCase.swift
//  NotBad
//
//  Application Layer - Use Case Implementation
//

import Foundation

// MARK: - StartReviewSessionUseCase

/// 开始复习会话用例实现
///
/// 实现 `StartReviewSessionUseCaseProtocol`，负责：
/// - 从仓库获取需要复习的题目
/// - 按复习模式排序和筛选
/// - 创建复习会话
@MainActor
final class StartReviewSessionUseCase: StartReviewSessionUseCaseProtocol {
    
    // MARK: - Dependencies
    
    private let repository: ReviewItemRepositoryProtocol
    
    // MARK: - Initialization
    
    init(repository: ReviewItemRepositoryProtocol) {
        self.repository = repository
    }
    
    // MARK: - StartReviewSessionUseCaseProtocol
    
    func execute(mode: SessionReviewMode) async throws -> ReviewSession {
        let items = fetchAndSort(mode: mode, subject: nil)
        return ReviewSession(items: items, mode: mode)
    }
    
    func execute(subject: Subject, mode: SessionReviewMode) async throws -> ReviewSession {
        let items = fetchAndSort(mode: mode, subject: subject)
        return ReviewSession(items: items, mode: mode)
    }
    
    func execute(itemIds: [UUID]) async throws -> ReviewSession {
        let allItems = repository.fetchAll()
        let items = allItems.filter { itemIds.contains($0.id) }
        
        guard !items.isEmpty else {
            throw StartReviewSessionError.noItemsFound
        }
        
        return ReviewSession(items: items, mode: .all)
    }
    
    // MARK: - Private Methods
    
    private func fetchAndSort(mode: SessionReviewMode, subject: Subject?) -> [ReviewItem] {
        var items: [ReviewItem]
        
        // 根据模式获取题目
        switch mode {
        case .smart:
            items = fetchForSmartMode(subject: subject)
        case .urgent:
            items = fetchForUrgentMode(subject: subject)
        case .random:
            items = fetchForRandomMode(subject: subject)
        case .all:
            items = fetchForAllMode(subject: subject)
        }
        
        // 限制数量
        if items.count > mode.maxItems {
            items = Array(items.prefix(mode.maxItems))
        }
        
        return items
    }
    
    /// 智能模式：优先逾期 + 按掌握程度排序
    private func fetchForSmartMode(subject: Subject?) -> [ReviewItem] {
        var items: [ReviewItem]
        
        if let subject = subject {
            items = repository.fetchForReview(subject: subject)
        } else {
            items = repository.fetchForReview()
        }
        
        // 按优先级排序：逾期 > 今日到期 > 掌握程度低
        return items.sorted { item1, item2 in
            // 逾期的优先
            let overdue1 = item1.nextReviewDate < Date()
            let overdue2 = item2.nextReviewDate < Date()
            if overdue1 != overdue2 {
                return overdue1
            }
            
            // 掌握程度低的优先
            return item1.masteryLevel < item2.masteryLevel
        }
    }
    
    /// 紧急模式：只选逾期题目
    private func fetchForUrgentMode(subject: Subject?) -> [ReviewItem] {
        let items: [ReviewItem]
        
        if let subject = subject {
            items = repository.fetchForReview(subject: subject)
        } else {
            items = repository.fetchOverdue()
        }
        
        // 按逾期天数排序
        return items.sorted { $0.nextReviewDate < $1.nextReviewDate }
    }
    
    /// 随机模式：随机选择
    private func fetchForRandomMode(subject: Subject?) -> [ReviewItem] {
        var items: [ReviewItem]
        
        if let subject = subject {
            items = repository.fetchForReview(subject: subject)
        } else {
            items = repository.fetchForReview()
        }
        
        return items.shuffled()
    }
    
    /// 全部模式：所有需要复习的题目
    private func fetchForAllMode(subject: Subject?) -> [ReviewItem] {
        if let subject = subject {
            return repository.fetchForReview(subject: subject)
        } else {
            return repository.fetchForReview()
        }
    }
}

// MARK: - StartReviewSessionError

/// 开始复习会话错误
enum StartReviewSessionError: Error, LocalizedError, Sendable {
    case noItemsFound
    case sessionCreationFailed(underlying: Error)
    
    var errorDescription: String? {
        switch self {
        case .noItemsFound:
            return String(localized: "没有找到需要复习的题目")
        case .sessionCreationFailed:
            return String(localized: "创建复习会话失败，请重试")
        }
    }
}
