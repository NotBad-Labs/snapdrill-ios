//
//  ReviewRepositoryProtocol.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//

import Foundation

/// 复习条目仓库协议（领域层）
///
/// 定义了对复习数据的基本 CRUD 操作，屏蔽持久化实现细节。
@MainActor
public protocol ReviewRepositoryProtocol: Sendable {
    /// 保存条目（新增或更新）
    func save(_ item: ReviewItem) throws
    
    /// 根据 ID 获取条目
    func fetchById(_ id: UUID) throws -> ReviewItem?
    
    /// 批量获取条目
    func fetchByIds(_ ids: Set<UUID>) throws -> [ReviewItem]
    
    /// 获取所有条目（慎用，建议使用分页）
    func fetchAll() throws -> [ReviewItem]
    
    /// 带过滤条件的分页查询
    func fetchFiltered(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItem]
    
    /// 获取总条数
    func totalCount() throws -> Int
    
    /// 删除条目
    func delete(id: UUID) throws
    
    /// 获取属于某学科的条目数量
    func countBySubject(name: String) throws -> Int
    
    /// 级联更新学科名称
    func updateSubjectUsage(from oldName: String, to newName: String) throws
    
    /// 获取属于某来源的条目数量
    func countBySource(name: String) throws -> Int

    /// 级联更新来源名称
    func updateSourceUsage(from oldName: String, to newName: String) throws

    /// 获取属于某年级的条目数量
    func countByGrade(name: String) throws -> Int

    /// 级联更新年级名称
    func updateGradeUsage(from oldName: String, to newName: String) throws

    /// 清空所有数据
    func deleteAll() throws

    // MARK: - Performance-Optimized Query Methods

    /// 获取所有待复习条目（nextReviewAt 为空或已到期）
    func fetchDueItems() throws -> [ReviewItem]

    /// 获取待复习条目总数
    func fetchDueCount() throws -> Int

    /// 获取今日新增条目数（createdAt >= 今日零点）
    func fetchTodayCount() throws -> Int

    /// 获取今日已复习条目数（lastReviewedAt >= 今日零点）
    func fetchTodayReviewedCount() throws -> Int

    /// 获取题库总条数（别名，与 totalCount 语义相同）
    func totalItemCount() throws -> Int
}
