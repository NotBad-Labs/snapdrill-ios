//
//  ReviewItemRepositoryProtocol.swift
//  NotBad
//
//  错题仓库协议 - 定义数据操作接口
//

import Foundation

/// 错题仓库协议
///
/// 定义错题数据的 CRUD 操作接口，便于：
/// 1. 依赖倒置 - 上层依赖抽象而非具体实现
/// 2. 可测试性 - 可以注入 Mock 实现
/// 3. 可替换性 - 未来可以替换存储方案
@MainActor
protocol ReviewItemRepositoryProtocol {
    /// 获取所有错题
    func fetchAll() -> [ReviewItem]
    
    /// 根据条件筛选错题
    func fetch(subject: Subject?, mastery: MasteryLevel?) -> [ReviewItem]
    
    /// 获取需要复习的错题（按优先级排序）
    func fetchForReview() -> [ReviewItem]
    
    /// 搜索错题
    func search(query: String) -> [ReviewItem]
    
    /// 保存错题
    func save(_ item: ReviewItem) throws
    
    /// 删除错题
    func delete(_ item: ReviewItem) throws
    
    /// 批量删除
    func delete(_ items: [ReviewItem]) throws
    
    /// 统计数据
    func statistics() -> ReviewStatistics
}

/// 错题统计数据
struct ReviewStatistics {
    let totalCount: Int
    let masteredCount: Int
    let weeklyNewCount: Int
    let totalReviewCount: Int
    
    /// 各掌握程度分布
    let masteryDistribution: [MasteryLevel: Int]
    
    /// 各学科分布
    let subjectDistribution: [Subject: Int]
}
