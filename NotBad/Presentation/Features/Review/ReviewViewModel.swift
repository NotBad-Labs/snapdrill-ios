//
//  ReviewViewModel.swift
//  NotBad
//
//  Created for NotBad K12 错题本
//  Phase 4: Use Case Integration
//

import SwiftUI
import SwiftData
import OSLog

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
/// ## 依赖注入（推荐方式）
///
/// ```swift
/// // 使用 DependencyFactory
/// let factory = AppDependencies.factory
/// let viewModel = ReviewViewModel(
///     startSessionUseCase: factory.makeStartReviewSessionUseCase(),
///     recordResultUseCase: factory.makeRecordReviewResultUseCase(),
///     completeSessionUseCase: factory.makeCompleteReviewSessionUseCase()
/// )
/// ```
///
/// ## 向后兼容
///
/// ```swift
/// // 旧方式仍然支持
/// let viewModel = ReviewViewModel()
/// viewModel.configure(with: modelContext)
/// ```
@MainActor
@Observable
final class ReviewViewModel {

    // MARK: - Use Cases (New Architecture)
    
    /// 获取错题用例
    private var fetchItemsUseCase: FetchReviewItemsUseCaseProtocol?
    
    /// 开始复习会话用例
    private var startSessionUseCase: StartReviewSessionUseCaseProtocol?
    
    /// 记录复习结果用例
    private var recordResultUseCase: RecordReviewResultUseCaseProtocol?
    
    /// 完成复习会话用例
    private var completeSessionUseCase: CompleteReviewSessionUseCaseProtocol?
    
    // MARK: - Data State
    
    /// 从 Use Case 加载的数据
    private(set) var loadedItems: [ReviewItem] = []
    
    /// 数据是否正在加载
    private(set) var isLoading = false

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

    // MARK: - Initialization

    /// 默认初始化
    init() {}
    
    /// Use Cases 注入初始化（推荐）
    ///
    /// - Parameters:
    ///   - startSessionUseCase: 开始复习会话用例
    ///   - recordResultUseCase: 记录复习结果用例
    ///   - completeSessionUseCase: 完成复习会话用例
    init(
        startSessionUseCase: StartReviewSessionUseCaseProtocol,
        recordResultUseCase: RecordReviewResultUseCaseProtocol,
        completeSessionUseCase: CompleteReviewSessionUseCaseProtocol
    ) {
        self.startSessionUseCase = startSessionUseCase
        self.recordResultUseCase = recordResultUseCase
        self.completeSessionUseCase = completeSessionUseCase
    }
    
    /// 完整 Use Cases 注入初始化（包含 fetch）
    ///
    /// - Parameters:
    ///   - fetchItemsUseCase: 获取错题用例
    ///   - startSessionUseCase: 开始复习会话用例
    ///   - recordResultUseCase: 记录复习结果用例
    ///   - completeSessionUseCase: 完成复习会话用例
    init(
        fetchItemsUseCase: FetchReviewItemsUseCaseProtocol,
        startSessionUseCase: StartReviewSessionUseCaseProtocol,
        recordResultUseCase: RecordReviewResultUseCaseProtocol,
        completeSessionUseCase: CompleteReviewSessionUseCaseProtocol
    ) {
        self.fetchItemsUseCase = fetchItemsUseCase
        self.startSessionUseCase = startSessionUseCase
        self.recordResultUseCase = recordResultUseCase
        self.completeSessionUseCase = completeSessionUseCase
    }
    
    // MARK: - Data Loading
    
    /// 加载所有错题（使用 Use Case）
    ///
    /// - Parameter forceRefresh: 强制刷新，忽略缓存
    func loadItems(forceRefresh: Bool = false) async {
        guard let fetchItemsUseCase else { return }
        
        // 如果已有数据且不强制刷新，跳过加载
        guard forceRefresh || loadedItems.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        loadedItems = await fetchItemsUseCase.execute()
    }

    // MARK: - Data Access

    /// 获取所有错题
    var items: [ReviewItem] {
        loadedItems
    }

    /// 生成复习队列
    ///
    /// - Returns: 排序后的复习队列
    func generateReviewQueue() -> [ReviewItem] {
        generateReviewQueue(from: items)
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
    ///   - reviewItem: 当前错题
    ///   - level: 评估的掌握程度
    func handleMasteryUpdate(for reviewItem: ReviewItem, level: MasteryLevel) {
        Task { @MainActor [weak self] in
            guard let self, let recordResultUseCase else {
                // Fallback: 本地更新
                reviewItem.recordReview(newMastery: level)
                self?.updateStatistics(level: level, reviewItem: reviewItem)
                return
            }
            
            do {
                // 判断是否正确（基本掌握/完全掌握视为正确）
                let isCorrect = level == .mastered || level == .good
                
                // 使用 Use Case 记录
                _ = try await recordResultUseCase.execute(
                    itemId: reviewItem.id,
                    isCorrect: isCorrect,
                    duration: 0  // 暂时不追踪用时
                )
                
                updateStatistics(level: level, reviewItem: reviewItem)
            } catch {
                Logger.data.error("记录复习结果失败: \(error)")
                // Fallback: 本地更新
                reviewItem.recordReview(newMastery: level)
                updateStatistics(level: level, reviewItem: reviewItem)
            }
        }
    }
    
    /// 更新复习统计
    private func updateStatistics(level: MasteryLevel, reviewItem: ReviewItem) {
        reviewedCount += 1
        masteryResults[level, default: 0] += 1
        
        // 发送通知
        NotificationCenter.default.post(name: .reviewItemUpdated, object: reviewItem)
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

