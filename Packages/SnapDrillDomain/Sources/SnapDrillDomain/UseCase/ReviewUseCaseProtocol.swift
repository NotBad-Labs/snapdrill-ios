//
//  ReviewUseCaseProtocol.swift
//  SnapDrillDomain
//
//  Created by SnapDrill Labs on 2026/02/27.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  核心职责：定义复习业务用例协议，承载核心调度与题库操作。
//

import Foundation

/// 复习业务用例协议
///
/// 承载了项目的核心业务逻辑，如：什么是“待复习”、复习算法的触发、学科统计等。
@MainActor
public protocol ReviewUseCaseProtocol: Sendable {
    /// 获取今日待复习的所有条目
    func getDueItems() throws -> [ReviewItem]
    
    /// 获取今日待复习的总数
    func getDueCount() throws -> Int
    
    /// 获取今日已完成复习的数量
    func getTodayReviewedCount() throws -> Int
    
    /// 保存并调度一个新题目
    func captureNewItem(_ item: ReviewItem) throws

    /// 更新已有题目
    func updateItem(_ item: ReviewItem) throws
    
    /// 获取今日新增题目的总数
    func getTodayAddedCount() throws -> Int
    
    /// 获取题库总题目数量
    func getTotalItemCount() throws -> Int
    
    /// 执行复习反馈（触发调度算法）
    func submitReviewResult(id: UUID, rating: ReviewRating) throws
    
    /// 全量题库的分页检索（带过滤）
    func searchLibrary(
        query: String,
        subjects: Set<String>,
        tags: Set<String>,
        page: Int,
        pageSize: Int
    ) throws -> [ReviewItem]
    
    /// 删除条目
    func deleteItem(id: UUID) throws
    
    /// 清空所有核心错题数据
    func deleteAllData() throws
    
    /// 获取所有题目（用于导出）
    func fetchAllItems() throws -> [ReviewItem]
    
    /// 根据 ID 列表批量获取题目
    func fetchItemsByIds(_ ids: Set<UUID>) throws -> [ReviewItem]
}
