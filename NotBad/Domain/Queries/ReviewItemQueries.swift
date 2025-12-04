//
//  ReviewItemQueries.swift
//  NotBad
//
//  Predicate 工厂 - CQRS 架构的 Query 层
//
//  将复杂的查询逻辑从 View 中抽离，保持 View 的清爽，
//  同时让查询逻辑可测试、可复用。
//

import Foundation
import SwiftData

// MARK: - ReviewItemQueries

/// ReviewItem 查询谓词工厂
///
/// 提供标准化的查询谓词，供 `@Query` 使用。
///
/// ## 设计原则
///
/// - **Single Responsibility**：每个方法只负责一种查询场景
/// - **Composable**：谓词可以组合使用
/// - **Testable**：逻辑集中，便于单元测试
///
/// ## 使用示例
///
/// ```swift
/// struct LibraryView: View {
///     @Query(filter: ReviewItemQueries.needsReview())
///     private var itemsToReview: [ReviewItem]
/// }
/// ```
enum ReviewItemQueries {
    
    // MARK: - Basic Predicates
    
    /// 需要复习的错题
    ///
    /// 筛选 `nextReviewDate <= 今天` 且未完全掌握的错题
    static func needsReview() -> Predicate<ReviewItem> {
        let today = Calendar.current.startOfDay(for: Date())
        let masteredLevel = MasteryLevel.mastered.rawValue
        return #Predicate<ReviewItem> { item in
            item.nextReviewDate <= today && item.masteryLevel < masteredLevel
        }
    }
    
    /// 已逾期的错题
    ///
    /// 筛选 `nextReviewDate < 今天` 的错题
    static func overdue() -> Predicate<ReviewItem> {
        let today = Calendar.current.startOfDay(for: Date())
        return #Predicate<ReviewItem> { item in
            item.nextReviewDate < today
        }
    }
    
    /// 已掌握的错题
    static func mastered() -> Predicate<ReviewItem> {
        let masteredLevel = MasteryLevel.mastered.rawValue
        return #Predicate<ReviewItem> { item in
            item.masteryLevel == masteredLevel
        }
    }
    
    /// 需要重点关注的错题（掌握度低）
    static func needsAttention() -> Predicate<ReviewItem> {
        let threshold = MasteryLevel.partial.rawValue
        return #Predicate<ReviewItem> { item in
            item.masteryLevel <= threshold
        }
    }
    
    // MARK: - Subject Filters
    
    /// 按学科筛选
    ///
    /// - Parameter subjectRaw: 学科的原始值
    /// - Returns: 匹配指定学科的谓词
    static func bySubject(_ subjectRaw: String) -> Predicate<ReviewItem> {
        #Predicate<ReviewItem> { item in
            item.subjectRaw == subjectRaw
        }
    }
    
    /// 按年级筛选
    ///
    /// - Parameter gradeRaw: 年级的原始值
    /// - Returns: 匹配指定年级的谓词
    static func byGrade(_ gradeRaw: String) -> Predicate<ReviewItem> {
        #Predicate<ReviewItem> { item in
            item.gradeRaw == gradeRaw
        }
    }
    
    // MARK: - Search Predicates
    
    /// 搜索标题
    ///
    /// - Parameter keyword: 搜索关键词
    /// - Returns: 标题包含关键词的谓词
    static func searchByTitle(_ keyword: String) -> Predicate<ReviewItem> {
        #Predicate<ReviewItem> { item in
            item.title.localizedStandardContains(keyword)
        }
    }
    
    // MARK: - Time-based Predicates
    
    /// 最近添加的错题
    ///
    /// - Parameter days: 最近几天内
    /// - Returns: 创建时间在指定天数内的谓词
    static func recentlyAdded(days: Int = 7) -> Predicate<ReviewItem> {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return #Predicate<ReviewItem> { item in
            item.createdAt >= cutoffDate
        }
    }
}

// MARK: - Sort Descriptors

/// ReviewItem 排序描述符工厂
enum ReviewItemSortDescriptors {
    
    /// 按创建时间排序（最新优先）
    static var byCreatedAt: [SortDescriptor<ReviewItem>] {
        [SortDescriptor(\.createdAt, order: .reverse)]
    }
    
    /// 按下次复习时间排序（最近优先）
    static var byNextReviewDate: [SortDescriptor<ReviewItem>] {
        [SortDescriptor(\.nextReviewDate, order: .forward)]
    }
    
    /// 按掌握度排序（最低优先，便于复习薄弱项）
    static var byMastery: [SortDescriptor<ReviewItem>] {
        [SortDescriptor(\.masteryLevel, order: .forward)]
    }
    
    /// 按更新时间排序（最近优先）
    static var byUpdatedAt: [SortDescriptor<ReviewItem>] {
        [SortDescriptor(\.updatedAt, order: .reverse)]
    }
    
    /// 复习优先级排序（逾期 > 今天 > 低掌握度）
    static var byReviewPriority: [SortDescriptor<ReviewItem>] {
        [
            SortDescriptor(\.nextReviewDate, order: .forward),
            SortDescriptor(\.masteryLevel, order: .forward)
        ]
    }
}
