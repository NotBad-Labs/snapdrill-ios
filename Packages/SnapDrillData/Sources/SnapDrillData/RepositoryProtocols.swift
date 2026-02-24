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
    /// 获取待复习条目数量
    func fetchDueCount() throws -> Int
    /// 获取总条目数量
    func totalItemCount() throws -> Int
    /// 根据 ID 查找
    func fetchById(_ id: UUID) throws -> ReviewItemModel?
    /// 更新条目
    func update(_ item: ReviewItem) throws
    /// 删除条目
    func delete(_ model: ReviewItemModel)
    /// 保存上下文
    func save() throws
}

// MARK: - SubjectRepository 协议

/// 学科仓库协议
@MainActor
public protocol SubjectRepositoryProtocol {
    /// 获取所有学科
    func fetchAll() throws -> [SubjectModel]
    /// 添加学科
    func add(name: String, icon: String, colorHex: String) throws
    /// 初始化默认学科
    func initializeDefaultsIfNeeded()
}

// MARK: - SourceRepository 协议

/// 来源仓库协议
@MainActor
public protocol SourceRepositoryProtocol {
    /// 获取所有来源
    func fetchAll() throws -> [SourceModel]
    /// 添加来源
    func add(name: String, icon: String, colorHex: String) throws
    /// 删除来源
    func delete(_ source: SourceModel)
    /// 初始化默认来源
    func seedDefaultSourcesIfNeeded()
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
