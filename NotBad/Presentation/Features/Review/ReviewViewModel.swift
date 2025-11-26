//
//  ReviewViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//

import SwiftUI
import SwiftData

// MARK: - ReviewViewModel

/// 复习 ViewModel
///
/// 负责管理错题复习的完整流程，包括复习队列、进度追踪和掌握度更新。
///
/// ## 复习流程
///
/// 1. **生成队列**：根据艾宾浩斯曲线和掌握程度排序
/// 2. **逐题复习**：显示错题，用户评估掌握程度
/// 3. **更新状态**：记录复习结果，计算下次复习时间
/// 4. **完成统计**：显示本次复习成果
///
/// ## 使用示例
///
/// ```swift
/// struct ReviewView: View {
///     @Query private var items: [ReviewItem]
///     @State private var viewModel = ReviewViewModel()
///
///     var body: some View {
///         let queue = viewModel.generateReviewQueue(from: items)
///         if let current = viewModel.currentItem(from: queue) {
///             ReviewCard(item: current)
///         }
///     }
/// }
/// ```
@MainActor
@Observable
final class ReviewViewModel {
    
    // MARK: - Review State
    
    /// 当前复习索引
    var currentIndex = 0
    
    /// 复习会话状态
    var sessionState: ReviewSessionState = .idle
    
    /// 是否显示完成弹窗
    var showCompletionAlert = false
    
    /// 是否显示退出确认
    var showExitConfirmation = false
    
    // MARK: - Statistics
    
    /// 本次复习计数
    var reviewedCount = 0
    
    /// 各掌握程度计数
    var masteryResults: [MasteryLevel: Int] = [:]
    
    /// 复习开始时间
    var sessionStartTime: Date?
    
    /// 已用时间（秒）
    var elapsedSeconds: Int {
        guard let start = sessionStartTime else { return 0 }
        return Int(Date().timeIntervalSince(start))
    }
    
    // MARK: - Filter State
    
    /// 复习模式
    var reviewMode: ReviewMode = .smart
    
    /// 筛选的学科
    var filterSubject: Subject?
    
    /// 每次复习数量限制
    var batchSize: Int = 20
    
    // MARK: - Dependencies
    
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Queue Generation
    
    /// 生成复习队列
    ///
    /// 根据复习模式和筛选条件生成优化的复习队列。
    ///
    /// - Parameter allItems: 所有错题
    /// - Returns: 排序后的复习队列
    func generateReviewQueue(from allItems: [ReviewItem]) -> [ReviewItem] {
        var items = allItems
        
        // 学科筛选
        if let subject = filterSubject {
            items = items.filter { $0.subject == subject }
        }
        
        // 根据模式筛选和排序
        switch reviewMode {
        case .smart:
            // 智能模式：优先复习需要复习的
            items = items
                .filter { $0.needsReview }
                .sorted { item1, item2 in
                    // 逾期优先
                    if item1.isOverdue != item2.isOverdue {
                        return item1.isOverdue
                    }
                    // 掌握程度低优先
                    if item1.masteryLevel != item2.masteryLevel {
                        return item1.masteryLevel < item2.masteryLevel
                    }
                    // 复习次数少优先
                    return item1.reviewCount < item2.reviewCount
                }
            
        case .weakest:
            // 薄弱项模式：按掌握程度从低到高
            items = items.sorted { $0.masteryLevel < $1.masteryLevel }
            
        case .random:
            // 随机模式
            items = items.shuffled()
            
        case .newest:
            // 最新添加
            items = items.sorted { $0.createdAt > $1.createdAt }
            
        case .overdue:
            // 仅逾期
            items = items.filter { $0.isOverdue }
                .sorted { $0.reviewInterval.overdueByDays > $1.reviewInterval.overdueByDays }
        }
        
        // 限制数量
        return Array(items.prefix(batchSize))
    }
    
    /// 获取当前复习项
    func currentItem(from queue: [ReviewItem]) -> ReviewItem? {
        guard currentIndex < queue.count else { return nil }
        return queue[currentIndex]
    }
    
    /// 复习进度（0.0 - 1.0）
    func progress(totalCount: Int) -> Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }
    
    /// 进度描述
    func progressDescription(totalCount: Int) -> String {
        "\(currentIndex + 1) / \(totalCount)"
    }
    
    // MARK: - Session Control
    
    /// 开始复习会话
    func startSession() {
        sessionState = .inProgress
        sessionStartTime = Date()
        currentIndex = 0
        reviewedCount = 0
        masteryResults = [:]
    }
    
    /// 暂停复习会话
    func pauseSession() {
        sessionState = .paused
    }
    
    /// 恢复复习会话
    func resumeSession() {
        sessionState = .inProgress
    }
    
    /// 结束复习会话
    func endSession() {
        sessionState = .completed
        showCompletionAlert = true
    }
    
    /// 重置会话
    func reset() {
        currentIndex = 0
        reviewedCount = 0
        masteryResults = [:]
        sessionState = .idle
        sessionStartTime = nil
        showCompletionAlert = false
    }
    
    // MARK: - Review Actions
    
    /// 处理掌握度更新
    ///
    /// 更新错题的掌握程度，计算下次复习时间。
    ///
    /// - Parameters:
    ///   - item: 当前错题
    ///   - level: 评估的掌握程度
    func handleMasteryUpdate(for item: ReviewItem, level: MasteryLevel) {
        guard let modelContext else { return }
        
        // 记录复习
        item.recordReview(newMastery: level)
        
        // 保存
        do {
            try modelContext.save()
        } catch {
            #if DEBUG
            print("❌ 保存失败: \(error)")
            #endif
        }
        
        // 更新统计
        reviewedCount += 1
        masteryResults[level, default: 0] += 1
        
        // 发送通知
        NotificationCenter.default.post(name: .reviewItemUpdated, object: item)
    }
    
    /// 移动到下一题
    func moveToNext(totalCount: Int) {
        if currentIndex < totalCount - 1 {
            currentIndex += 1
        } else {
            endSession()
        }
    }
    
    /// 移动到上一题
    func moveToPrevious() {
        if currentIndex > 0 {
            currentIndex -= 1
        }
    }
    
    /// 跳过当前题
    func skipCurrent(totalCount: Int) {
        moveToNext(totalCount: totalCount)
    }
    
    // MARK: - Session Statistics
    
    /// 生成会话统计
    func generateSessionStatistics() -> ReviewSessionStatistics {
        ReviewSessionStatistics(
            totalReviewed: reviewedCount,
            elapsedSeconds: elapsedSeconds,
            masteryResults: masteryResults
        )
    }
    
    /// 平均每题用时（秒）
    var averageTimePerItem: Int {
        guard reviewedCount > 0 else { return 0 }
        return elapsedSeconds / reviewedCount
    }
    
    /// 掌握率（本次）
    var sessionMasteryRate: Double {
        guard reviewedCount > 0 else { return 0 }
        let goodCount = (masteryResults[.mastered] ?? 0) + (masteryResults[.good] ?? 0)
        return Double(goodCount) / Double(reviewedCount)
    }
}

// MARK: - ReviewMode

/// 复习模式
enum ReviewMode: String, CaseIterable, Identifiable {
    case smart = "智能推荐"
    case weakest = "薄弱项优先"
    case random = "随机复习"
    case newest = "最新添加"
    case overdue = "仅逾期"
    
    var id: String { rawValue }
    var displayName: String { rawValue }
    
    var icon: String {
        switch self {
        case .smart: "brain"
        case .weakest: "exclamationmark.triangle"
        case .random: "shuffle"
        case .newest: "clock"
        case .overdue: "calendar.badge.exclamationmark"
        }
    }
    
    var description: String {
        switch self {
        case .smart: "根据艾宾浩斯曲线智能排序"
        case .weakest: "优先复习掌握程度低的"
        case .random: "随机打乱顺序"
        case .newest: "优先复习最新添加的"
        case .overdue: "只显示已逾期的错题"
        }
    }
}

// MARK: - ReviewSessionState

/// 复习会话状态
enum ReviewSessionState: Sendable {
    case idle
    case inProgress
    case paused
    case completed
    
    var isActive: Bool {
        self == .inProgress || self == .paused
    }
}

// MARK: - ReviewSessionStatistics

/// 复习会话统计
struct ReviewSessionStatistics: Sendable, Equatable {
    let totalReviewed: Int
    let elapsedSeconds: Int
    let masteryResults: [MasteryLevel: Int]
    
    /// 格式化的用时
    var formattedDuration: String {
        let minutes = elapsedSeconds / 60
        let seconds = elapsedSeconds % 60
        
        if minutes > 0 {
            return "\(minutes) 分 \(seconds) 秒"
        } else {
            return "\(seconds) 秒"
        }
    }
    
    /// 掌握率
    var masteryRate: Double {
        guard totalReviewed > 0 else { return 0 }
        let goodCount = (masteryResults[.mastered] ?? 0) + (masteryResults[.good] ?? 0)
        return Double(goodCount) / Double(totalReviewed)
    }
    
    /// 掌握率描述
    var masteryRateDescription: String {
        "\(Int(masteryRate * 100))%"
    }
    
    /// 是否表现良好
    var isGoodPerformance: Bool {
        masteryRate >= 0.6
    }
    
    /// 鼓励语
    var encouragement: String {
        switch masteryRate {
        case 0.8...: "太棒了！继续保持！🎉"
        case 0.6..<0.8: "做得不错！再接再厉！💪"
        case 0.4..<0.6: "继续努力，你可以的！📚"
        default: "多复习几遍，一定能掌握！🌟"
        }
    }
}
