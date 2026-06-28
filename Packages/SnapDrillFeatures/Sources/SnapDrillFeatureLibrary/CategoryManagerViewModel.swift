//
//  CategoryManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  分类维度管理 ViewModel（L3）：维度列表加载、新建、删除（仅用户维度）。
//  取代旧固定分类/来源/级别三套同构管理 VM。
//

import Foundation
import Observation
import SnapDrillData
import SnapDrillCore

/// 分类维度管理 ViewModel
///
/// 负责命名维度（分类/来源/级别/标签 + 用户自定义）的列表、新建与删除。
/// 单个维度内的值增删改、单值/多值开关、可见性开关下沉到 `CategoryValueListViewModel`。
@Observable
public final class CategoryManagerViewModel {

    // MARK: - State

    /// 当前所有维度（按 sortOrder）
    public private(set) var dimensions: [CategoryDimensionModel] = []
    /// 删除受阻：维度下仍有值被题目引用（与值级删除守卫对称，防静默剥离题目分类）
    public var isDeletingInUse = false
    /// 触发删除保护时的维度名称
    public var pendingDeletionName = ""
    /// 重名保护：目标名称已存在
    public var isDuplicateName = false
    /// 触发重名保护时的名称
    public var duplicateNameValue = ""
    /// 保存失败时展示给 UI 的错误信息
    public var operationError: String?

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - Initialization

    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public Actions

    /// 加载维度列表（已按 sortOrder 排序）
    public func loadData() {
        do {
            dimensions = try repositories.dimension.fetchAllModels()
        } catch {
            SnapDrillLogger.data.error("加载维度列表失败: \(error.localizedDescription)")
        }
    }

    /// 新建用户维度（systemKey=nil、isBuiltIn=false）
    /// - Returns: 是否成功（重名时返回 false，View 据此决定是否 dismiss）
    @discardableResult
    public func addDimension(name: String, isMultiValue: Bool, icon: String) -> Bool {
        isDuplicateName = false
        operationError = nil
        // 重名校验：跨内置/用户维度统一不允许同名（维度名是导出列名，须唯一）
        if dimensions.contains(where: { $0.name == name }) {
            isDuplicateName = true
            duplicateNameValue = name
            return false
        }
        do {
            let sortOrder = try repositories.dimension.totalCount()
            let model = CategoryDimensionModel(
                name: name,
                isMultiValue: isMultiValue,
                isBuiltIn: false,
                systemKey: nil,
                sortOrder: sortOrder,
                icon: icon
            )
            try repositories.dimension.insertAndSave(model)
            loadData()
            return true
        } catch {
            repositories.dimension.rollbackContext()
            SnapDrillLogger.generic.error("新建维度失败: \(error.localizedDescription)")
            operationError = L10n.Errors.saveFailed
            return false
        }
    }

    /// 删除指定位置的维度。内置维度跳过（UI 不提供删除入口，此处为双保险）。
    /// 与值级删除守卫对称：维度下任一值仍被题目引用时拦截（删整维度=批量删值+批量解引用，
    /// 破坏性更大，更需守护），置 `isDeletingInUse` 并跳过，不静默剥离题目分类。
    /// 确认可删后，Repository `delete(id:)` 显式遍历删值 + 解题目引用（不靠 cascade）。
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let toDelete = offsets.compactMap { dimensions.indices.contains($0) ? dimensions[$0] : nil }
        for dimension in toDelete {
            guard !dimension.isBuiltIn else { continue }
            let inUse = (dimension.values ?? []).contains { ($0.items?.count ?? 0) > 0 }
            if inUse {
                isDeletingInUse = true
                pendingDeletionName = dimension.name
                continue
            }
            do {
                try repositories.dimension.delete(id: dimension.id)
            } catch {
                SnapDrillLogger.generic.error("删除维度失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }
}
