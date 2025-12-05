//
//  StartReviewSessionUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - StartReviewSessionUseCaseProtocol

/// 开始复习会话用例协议
///
/// 负责创建一个新的复习会话，包含：
/// - 获取需要复习的题目
/// - 按复习算法排序
/// - 限制单次复习数量
///
/// ## 业务规则
///
/// 1. 优先选择逾期题目
/// 2. 按掌握程度从低到高排序
/// 3. 单次复习不超过 20 题
/// 4. 如果没有需要复习的题目，返回空会话
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeStartReviewSessionUseCase()
/// let session = try await useCase.execute(mode: .smart)
/// ```
@MainActor
protocol StartReviewSessionUseCaseProtocol: Sendable {
    
    /// 开始复习会话
    ///
    /// - Parameter mode: 复习模式
    /// - Returns: 复习会话，包含待复习题目
    /// - Throws: 创建会话失败时抛出错误
    func execute(mode: SessionReviewMode) async throws -> ReviewSession
    
    /// 开始指定学科的复习会话
    ///
    /// - Parameters:
    ///   - subject: 学科
    ///   - mode: 复习模式
    /// - Returns: 复习会话
    /// - Throws: 创建会话失败时抛出错误
    func execute(subject: Subject, mode: SessionReviewMode) async throws -> ReviewSession
    
    /// 开始指定题目的复习会话
    ///
    /// - Parameter itemIds: 题目 ID 列表
    /// - Returns: 复习会话
    /// - Throws: 创建会话失败时抛出错误
    func execute(itemIds: [UUID]) async throws -> ReviewSession
}

// MARK: - SessionReviewMode

/// 复习会话模式（Domain 层）
///
/// 用于 Use Case 的复习模式定义，与 Presentation 层的 ReviewMode 独立。
/// 在 ViewModel 中需要进行映射转换。
enum SessionReviewMode: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    /// 智能模式：按算法推荐
    case smart
    
    /// 紧急模式：只复习逾期题目
    case urgent
    
    /// 随机模式：随机选择
    case random
    
    /// 全部模式：复习所有需要复习的题目
    case all
    
    nonisolated var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .smart: return String(localized: "智能推荐")
        case .urgent: return String(localized: "紧急复习")
        case .random: return String(localized: "随机练习")
        case .all: return String(localized: "全部复习")
        }
    }
    
    var icon: String {
        switch self {
        case .smart: return "brain.head.profile"
        case .urgent: return "exclamationmark.triangle"
        case .random: return "shuffle"
        case .all: return "list.bullet"
        }
    }
    
    /// 单次复习最大题目数
    var maxItems: Int {
        switch self {
        case .smart: return 20
        case .urgent: return 10
        case .random: return 15
        case .all: return 50
        }
    }
}

// MARK: - ReviewSession

/// 复习会话
///
/// 代表一次完整的复习过程，从开始到结束。
///
/// - Note: 使用 `@unchecked Sendable` 因为 ReviewItem 是引用类型，
///         但在实际使用中会在 MainActor 上下文中操作。
struct ReviewSession: Identifiable, @unchecked Sendable {
    
    /// 会话 ID
    let id: UUID
    
    /// 待复习题目
    let items: [ReviewItem]
    
    /// 复习模式
    let mode: SessionReviewMode
    
    /// 开始时间
    let startedAt: Date
    
    /// 当前进度（已完成数量）
    var currentIndex: Int
    
    /// 复习结果记录
    var results: [ReviewResult]
    
    // MARK: - Computed Properties
    
    /// 总题目数
    var totalCount: Int { items.count }
    
    /// 是否为空会话
    var isEmpty: Bool { items.isEmpty }
    
    /// 是否已完成
    var isCompleted: Bool { currentIndex >= items.count }
    
    /// 进度百分比
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(currentIndex) / Double(totalCount)
    }
    
    /// 当前题目
    var currentItem: ReviewItem? {
        guard currentIndex < items.count else { return nil }
        return items[currentIndex]
    }
    
    /// 正确率
    var correctRate: Double {
        guard !results.isEmpty else { return 0 }
        let correctCount = results.filter { $0.isCorrect }.count
        return Double(correctCount) / Double(results.count)
    }
    
    // MARK: - Initialization
    
    init(
        id: UUID = UUID(),
        items: [ReviewItem],
        mode: SessionReviewMode,
        startedAt: Date = Date(),
        currentIndex: Int = 0,
        results: [ReviewResult] = []
    ) {
        self.id = id
        self.items = items
        self.mode = mode
        self.startedAt = startedAt
        self.currentIndex = currentIndex
        self.results = results
    }
    
    // MARK: - Methods
    
    /// 前进到下一题
    mutating func moveToNext() {
        guard currentIndex < items.count else { return }
        currentIndex += 1
    }
    
    /// 记录当前题目的复习结果
    mutating func recordResult(_ result: ReviewResult) {
        results.append(result)
    }
}

// MARK: - ReviewResult

/// 单题复习结果
struct ReviewResult: Identifiable, Sendable, Codable {
    
    /// 结果 ID
    let id: UUID
    
    /// 题目 ID
    let itemId: UUID
    
    /// 是否正确
    let isCorrect: Bool
    
    /// 新的掌握程度
    let newMasteryLevel: MasteryLevel
    
    /// 用时（秒）
    let duration: TimeInterval
    
    /// 记录时间
    let recordedAt: Date
    
    init(
        id: UUID = UUID(),
        itemId: UUID,
        isCorrect: Bool,
        newMasteryLevel: MasteryLevel,
        duration: TimeInterval,
        recordedAt: Date = Date()
    ) {
        self.id = id
        self.itemId = itemId
        self.isCorrect = isCorrect
        self.newMasteryLevel = newMasteryLevel
        self.duration = duration
        self.recordedAt = recordedAt
    }
}
