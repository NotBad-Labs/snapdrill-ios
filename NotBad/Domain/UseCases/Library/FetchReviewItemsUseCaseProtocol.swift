//
//  FetchReviewItemsUseCaseProtocol.swift
//  NotBad
//
//  Domain Layer - Use Case Protocol
//

import Foundation

// MARK: - FetchReviewItemsUseCaseProtocol

/// 获取错题用例协议
///
/// 负责获取和筛选错题列表：
/// - 支持多条件筛选
/// - 支持排序
/// - 支持分页（可选）
///
/// ## 使用示例
///
/// ```swift
/// let useCase = dependencies.makeFetchReviewItemsUseCase()
/// let items = try await useCase.execute(
///     filter: .init(subject: .math, mastery: .notMastered)
/// )
/// ```
@MainActor
protocol FetchReviewItemsUseCaseProtocol: Sendable {
    
    /// 获取所有错题
    ///
    /// - Returns: 错题列表
    func execute() async -> [ReviewItem]
    
    /// 按条件筛选错题
    ///
    /// - Parameter filter: 筛选条件
    /// - Returns: 符合条件的错题列表
    func execute(filter: ReviewItemFilter) async -> [ReviewItem]
    
    /// 搜索错题
    ///
    /// - Parameter query: 搜索关键词
    /// - Returns: 匹配的错题列表
    func execute(query: String) async -> [ReviewItem]
    
    /// 获取单个错题
    ///
    /// - Parameter id: 题目 ID
    /// - Returns: 错题，如果不存在返回 nil
    func execute(id: UUID) async -> ReviewItem?
}

// MARK: - ReviewItemFilter

/// 错题筛选条件
struct ReviewItemFilter: Sendable, Equatable {
    
    /// 学科筛选
    var subject: Subject?
    
    /// 年级筛选
    var grade: Grade?
    
    /// 掌握程度筛选
    var mastery: MasteryLevel?
    
    /// 难度筛选
    var difficulty: Difficulty?
    
    /// 错误类型筛选
    var errorType: ErrorType?
    
    /// 时间范围筛选
    var dateRange: DateRange?
    
    /// 排序方式
    var sortBy: ReviewItemSortOption
    
    /// 是否升序
    var ascending: Bool
    
    // MARK: - Initialization
    
    init(
        subject: Subject? = nil,
        grade: Grade? = nil,
        mastery: MasteryLevel? = nil,
        difficulty: Difficulty? = nil,
        errorType: ErrorType? = nil,
        dateRange: DateRange? = nil,
        sortBy: ReviewItemSortOption = .createdAt,
        ascending: Bool = false
    ) {
        self.subject = subject
        self.grade = grade
        self.mastery = mastery
        self.difficulty = difficulty
        self.errorType = errorType
        self.dateRange = dateRange
        self.sortBy = sortBy
        self.ascending = ascending
    }
    
    /// 默认筛选（无筛选）
    static let `default` = ReviewItemFilter()
    
    /// 是否有任何筛选条件
    var hasFilters: Bool {
        subject != nil ||
        grade != nil ||
        mastery != nil ||
        difficulty != nil ||
        errorType != nil ||
        dateRange != nil
    }
    
    /// 活跃的筛选条件数量
    var activeFilterCount: Int {
        var count = 0
        if subject != nil { count += 1 }
        if grade != nil { count += 1 }
        if mastery != nil { count += 1 }
        if difficulty != nil { count += 1 }
        if errorType != nil { count += 1 }
        if dateRange != nil { count += 1 }
        return count
    }
}

// MARK: - ReviewItemSortOption

/// 错题排序选项
enum ReviewItemSortOption: String, Sendable, CaseIterable, Codable, Hashable, Identifiable {
    case createdAt      // 创建时间
    case updatedAt      // 更新时间
    case nextReviewDate // 下次复习时间
    case mastery        // 掌握程度
    case difficulty     // 难度
    case reviewCount    // 复习次数
    case title          // 标题
    
    nonisolated var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .createdAt: return String(localized: "创建时间")
        case .updatedAt: return String(localized: "更新时间")
        case .nextReviewDate: return String(localized: "复习时间")
        case .mastery: return String(localized: "掌握程度")
        case .difficulty: return String(localized: "难度")
        case .reviewCount: return String(localized: "复习次数")
        case .title: return String(localized: "标题")
        }
    }
    
    var icon: String {
        switch self {
        case .createdAt: return "calendar.badge.plus"
        case .updatedAt: return "calendar.badge.clock"
        case .nextReviewDate: return "clock"
        case .mastery: return "chart.bar"
        case .difficulty: return "star"
        case .reviewCount: return "repeat"
        case .title: return "textformat"
        }
    }
}

// MARK: - DateRange

/// 日期范围
struct DateRange: Sendable, Equatable {
    let start: Date
    let end: Date
    
    /// 今天
    static var today: DateRange {
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }
    
    /// 本周
    static var thisWeek: DateRange {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let end = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }
    
    /// 本月
    static var thisMonth: DateRange {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now))!
        let end = Calendar.current.date(byAdding: .month, value: 1, to: start)!
        return DateRange(start: start, end: end)
    }
    
    /// 最近 N 天
    static func last(days: Int) -> DateRange {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -days, to: now)!
        return DateRange(start: start, end: now)
    }
}
