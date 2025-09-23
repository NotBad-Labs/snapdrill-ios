//
//  ReviewSessionUseCase.swift
//  NotBad
//
//  Created by Yiming Liao on 9/21/25.
//

import Foundation

/// 复习会话用例
/// 管理复习流程的Application Service
final class ReviewSessionUseCase {
    
    // MARK: - Dependencies
    private let reviewItemService: ReviewItemService
    
    // MARK: - State
    private var currentSession: ActiveReviewSession?
    
    // MARK: - Initialization
    init(reviewItemService: ReviewItemService) {
        self.reviewItemService = reviewItemService
    }
    
    // MARK: - Use Cases
    
    /// 开始复习会话
    /// - Parameters:
    ///   - date: 复习日期
    ///   - maxItems: 最大复习项目数
    /// - Returns: 复习会话信息
    func startReviewSession(
        on date: Date = Date(),
        maxItems: Int = 20
    ) async throws -> ReviewSessionInfo {
        // 如果已有会话在进行中，则不允许再次开始
        if currentSession != nil {
            throw ReviewSessionError.sessionAlreadyInProgress
        }
        // 获取需要复习的项目
        let itemsToReview = try await reviewItemService.getItemsForReview(
            date: date,
            limit: maxItems
        )
        
        guard !itemsToReview.isEmpty else {
            throw ReviewSessionError.noItemsToReview
        }
        
        // 创建活跃会话
        currentSession = ActiveReviewSession(
            items: itemsToReview,
            startTime: Date()
        )
        
        return ReviewSessionInfo(
            totalItems: itemsToReview.count,
            currentIndex: 0,
            currentItem: itemsToReview.first!,
            progress: 0.0,
            sessionId: currentSession!.sessionId
        )
    }
    
    /// 提交当前题目的答案
    /// - Parameters:
    ///   - sessionId: 会话ID
    ///   - wasSuccessful: 是否答对
    /// - Returns: 下一题信息或会话结果
    func submitAnswer(
        sessionId: UUID,
        wasSuccessful: Bool
    ) async throws -> ReviewSessionProgress {
        guard let session = currentSession,
              session.sessionId == sessionId else {
            throw ReviewSessionError.invalidSession
        }
        
        let currentItem = session.currentItem
        
        // 记录复习结果
        try await reviewItemService.recordReviewResult(
            id: currentItem.id,
            wasSuccessful: wasSuccessful
        )
        
        // 更新会话状态
        session.recordAnswer(wasSuccessful: wasSuccessful)
        
        // 检查是否还有下一题
        if session.hasNextItem {
            session.moveToNext()
            return .nextItem(ReviewSessionInfo(
                totalItems: session.totalItems,
                currentIndex: session.currentIndex,
                currentItem: session.currentItem,
                progress: session.progress,
                sessionId: session.sessionId
            ))
        } else {
            // 会话完成
            let result = generateSessionResult(session)
            currentSession = nil
            return .completed(result)
        }
    }
    
    /// 获取当前会话状态
    /// - Parameter sessionId: 会话ID
    /// - Returns: 会话信息
    func getCurrentSessionInfo(sessionId: UUID) throws -> ReviewSessionInfo? {
        guard let session = currentSession,
              session.sessionId == sessionId else {
            return nil
        }
        
        return ReviewSessionInfo(
            totalItems: session.totalItems,
            currentIndex: session.currentIndex,
            currentItem: session.currentItem,
            progress: session.progress,
            sessionId: session.sessionId
        )
    }
    
    /// 结束当前会话
    /// - Parameter sessionId: 会话ID
    /// - Returns: 会话结果
    func endSession(sessionId: UUID) throws -> ReviewSessionResult {
        guard let session = currentSession,
              session.sessionId == sessionId else {
            throw ReviewSessionError.invalidSession
        }
        
        let result = generateSessionResult(session)
        currentSession = nil
        return result
    }
}

// MARK: - Private Methods
private extension ReviewSessionUseCase {
    
    func generateSessionResult(_ session: ActiveReviewSession) -> ReviewSessionResult {
        let duration = Date().timeIntervalSince(session.startTime)
        let correctAnswers = session.results.filter(\.wasSuccessful).count
        let totalAnswered = session.results.count
        let accuracy = totalAnswered > 0 ? Double(correctAnswers) / Double(totalAnswered) : 0.0
        
        return ReviewSessionResult(
            sessionId: session.sessionId,
            totalItems: session.totalItems,
            completedItems: totalAnswered,
            correctAnswers: correctAnswers,
            accuracy: accuracy,
            duration: duration,
            startTime: session.startTime,
            endTime: Date()
        )
    }
}

// MARK: - Models

/// 活跃的复习会话
private class ActiveReviewSession {
    let sessionId: UUID
    let items: [ReviewItem]
    let startTime: Date
    private(set) var currentIndex: Int = 0
    private(set) var results: [ReviewResult] = []
    
    init(items: [ReviewItem], startTime: Date) {
        self.sessionId = UUID()
        self.items = items
        self.startTime = startTime
    }
    
    var totalItems: Int { items.count }
    var currentItem: ReviewItem { items[currentIndex] }
    var hasNextItem: Bool { currentIndex + 1 < items.count }
    // Progress reflects completed answers over total items, range [0,1].
    var progress: Double { totalItems > 0 ? Double(results.count) / Double(totalItems) : 0.0 }
    
    func recordAnswer(wasSuccessful: Bool) {
        results.append(ReviewResult(
            itemId: currentItem.id,
            wasSuccessful: wasSuccessful,
            timestamp: Date()
        ))
    }
    
    func moveToNext() {
        currentIndex += 1
    }
}

/// 复习结果记录
private struct ReviewResult {
    let itemId: ReviewItemID
    let wasSuccessful: Bool
    let timestamp: Date
}

/// 复习会话信息
struct ReviewSessionInfo {
    let totalItems: Int
    let currentIndex: Int
    let currentItem: ReviewItem
    let progress: Double
    let sessionId: UUID
}

/// 复习会话进度
enum ReviewSessionProgress {
    case nextItem(ReviewSessionInfo)
    case completed(ReviewSessionResult)
}

/// 复习会话结果
struct ReviewSessionResult {
    let sessionId: UUID
    let totalItems: Int
    let completedItems: Int
    let correctAnswers: Int
    let accuracy: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    
    var grade: ReviewGrade {
        switch accuracy {
        case 0.9...:
            return .excellent
        case 0.8..<0.9:
            return .good
        case 0.6..<0.8:
            return .fair
        default:
            return .needsImprovement
        }
    }
}

enum ReviewGrade: String {
    case excellent = "优秀"
    case good = "良好"
    case fair = "及格"
    case needsImprovement = "需要改进"
}

// MARK: - Errors

enum ReviewSessionError: Error, LocalizedError {
    case noItemsToReview
    case invalidSession
    case sessionAlreadyInProgress
    
    var errorDescription: String? {
        switch self {
        case .noItemsToReview:
            return "当前没有需要复习的项目"
        case .invalidSession:
            return "无效的复习会话"
        case .sessionAlreadyInProgress:
            return "已有复习会话在进行中"
        }
    }
}