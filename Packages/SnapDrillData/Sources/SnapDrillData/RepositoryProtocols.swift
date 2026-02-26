//
//  RepositoryProtocols.swift
//  SnapDrillData
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//
//  数据仓库协议定义，抽象 CRUD 操作以支持测试注入
//

import Foundation
import SnapDrillCore

// MARK: - ReviewRepository 协议

/// 复习条目仓库协议
///
/// 抽象复习数据的 CRUD 操作，使 ViewModel 和测试可以注入 Mock。
/// Abstracts review data CRUD for testable ViewModel injection.
@MainActor
public protocol ReviewRepositoryProtocol {
    /// 保存新的复习条目
    func save(_ item: ReviewItem, subject: String) throws
    /// 获取所有复习条目
    func fetchAll() throws -> [ReviewItemModel]
    /// 分页且带过滤条件的获取
    func fetchFiltered(
        searchText: String,
        subjects: Set<String>,
        tags: Set<String>,
        limit: Int,
        offset: Int
    ) throws -> [ReviewItemModel]
    /// 获取待复习条目数量
    func fetchDueCount() throws -> Int
    /// 获取今日新增条目数量
    func fetchTodayCount() throws -> Int
    /// 获取总条目数量
    func totalItemCount() throws -> Int
    /// 获取今日待复习条目
    func fetchDueItems() throws -> [ReviewItemModel]
    /// 获取今日已复习的条目数量
    func fetchTodayReviewedCount() throws -> Int
    /// 根据 ID 查找
    func fetchById(_ id: UUID) throws -> ReviewItemModel?
    /// 批量根据 ID 获取模型
    func fetchByIds(_ ids: Set<UUID>) throws -> [ReviewItemModel]
    /// 更新条目
    func update(_ item: ReviewItem) throws
    /// 删除条目
    func delete(_ model: ReviewItemModel)
    /// 清空所有数据
    func deleteAll() throws
    /// 保存上下文
    func save() throws
    /// 级联更新学科名称
    func updateSubjectUsage(from oldName: String, to newName: String) throws
    /// 级联更新来源名称
    func updateSourceUsage(from oldName: String, to newName: String) throws
}

// MARK: - SubjectRepository 协议

/// 学科仓库协议
@MainActor
public protocol SubjectRepositoryProtocol {
    /// 获取所有学科
    func fetchAll() throws -> [SubjectModel]
    /// 添加学科
    func add(name: String, icon: String, colorHex: String) throws
    /// 更新学科
    func update(_ subject: SubjectModel, name: String, icon: String, colorHex: String) throws
    /// 删除学科
    func delete(_ subject: SubjectModel)
    /// 清空所有学科
    func deleteAll() throws
    /// 初始化默认学科
    func initializeDefaultsIfNeeded()
    /// 保存上下文
    func save() throws
    /// 获取特定学科下的题目数量
    func countItems(named: String) throws -> Int
    /// 检查学科是否被使用
    func isSubjectInUse(_ subject: SubjectModel) throws -> Bool
}

// MARK: - SourceRepository 协议

/// 来源仓库协议
@MainActor
public protocol SourceRepositoryProtocol {
    /// 获取所有来源
    func fetchAll() throws -> [SourceModel]
    /// 添加来源
    func add(name: String, icon: String, colorHex: String) throws
    /// 更新来源
    func update(_ source: SourceModel, name: String, icon: String, colorHex: String) throws
    /// 删除来源
    func delete(_ source: SourceModel)
    /// 清空所有来源
    func deleteAll() throws
    /// 初始化默认来源
    func seedDefaultSourcesIfNeeded()
    /// 保存上下文
    func save() throws
    /// 获取特定来源下的题目数量
    func countItems(named: String) throws -> Int
}

// MARK: - TagRepository 协议

/// 标签仓库协议
@MainActor
public protocol TagRepositoryProtocol {
    /// 获取所有标签
    func fetchAll() throws -> [TagModel]
    /// 根据名称查找
    func fetchByName(_ name: String) throws -> TagModel?
    /// 添加标签
    @discardableResult
    func add(name: String, colorHex: String) throws -> TagModel
    /// 获取或创建标签
    func getOrCreate(name: String, colorHex: String) throws -> TagModel
    /// 删除标签
    func delete(_ tag: TagModel)
    /// 保存上下文
    func save() throws
}
