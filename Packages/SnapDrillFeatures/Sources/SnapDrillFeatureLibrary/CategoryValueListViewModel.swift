//
//  CategoryValueListViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  单个维度的详情 ViewModel（L3）：值增删改 + 维度级开关（单值/多值、录入页可见性）。
//

import Foundation
import Observation
import SnapDrillData
import SnapDrillCore

/// 维度详情 ViewModel：管理某一维度下的值，以及该维度的两个开关。
@Observable
public final class CategoryValueListViewModel {

    // MARK: - State

    /// 当前维度下的所有值（按 sortOrder）
    public private(set) var values: [CategoryValueModel] = []

    /// 是否在录入/编辑页显示该维度（写穿到共享的 `captureVisibilityKey`）
    public var isVisibleInCapture: Bool {
        didSet { UserDefaults.standard.set(isVisibleInCapture, forKey: dimension.captureVisibilityKey) }
    }

    /// 单值/多值开关（内置维度不可改，UI 已 disable，此处 didSet 再次 guard）
    public var isMultiValue: Bool {
        didSet { persistMultiValue() }
    }

    /// 删除受阻：值仍被题目引用
    public var isDeletingInUse = false
    /// 触发删除保护时的值名称
    public var pendingDeletionName = ""
    /// 重名保护
    public var isDuplicateName = false
    /// 触发重名保护时的名称
    public var duplicateNameValue = ""
    /// 保存失败时展示给 UI 的错误信息
    public var operationError: String?

    // MARK: - Dependencies

    /// 该维度（非 private，View 需读 name/icon/isBuiltIn 渲染标题与禁用态）
    public let dimension: CategoryDimensionModel
    private let repositories: RepositoryContainer

    // MARK: - Initialization

    public init(dimension: CategoryDimensionModel, repositories: RepositoryContainer) {
        self.dimension = dimension
        self.repositories = repositories
        // 注意：didSet 不在 init 阶段触发，故此处仅初始化、不写穿
        self.isVisibleInCapture = UserDefaults.standard.object(forKey: dimension.captureVisibilityKey) as? Bool ?? true
        self.isMultiValue = dimension.isMultiValue
    }

    // MARK: - Public Actions

    /// 加载该维度下的值（已按 sortOrder + id tiebreaker 排序）
    public func loadData() {
        values = repositories.categoryValue.fetchAllModels(in: dimension)
    }

    /// 删除指定位置的值；若值仍被题目引用，置 `isDeletingInUse` 并跳过
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let toDelete = offsets.compactMap { values.indices.contains($0) ? values[$0] : nil }
        for value in toDelete {
            if (value.items?.count ?? 0) > 0 {
                isDeletingInUse = true
                pendingDeletionName = value.name
                continue
            }
            do {
                try repositories.categoryValue.delete(id: value.id)
            } catch {
                SnapDrillLogger.generic.error("删除维度值失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }

    /// 新建或更新值。
    /// 关系化收益：重命名直接改 `value.name`，所有引用题目自动跟随，无需级联更新。
    /// - Returns: 是否成功（重名返回 false）
    @discardableResult
    public func saveValue(value: CategoryValueModel?, name: String, icon: String, colorHex: String) -> Bool {
        isDuplicateName = false
        operationError = nil
        do {
            if let value {
                if value.name != name,
                   repositories.categoryValue.fetchModel(byName: name, in: dimension) != nil {
                    isDuplicateName = true
                    duplicateNameValue = name
                    return false
                }
                value.name = name
                value.icon = icon
                value.colorHex = colorHex
                try repositories.categoryValue.saveContext()
            } else {
                if repositories.categoryValue.fetchModel(byName: name, in: dimension) != nil {
                    isDuplicateName = true
                    duplicateNameValue = name
                    return false
                }
                let model = CategoryValueModel(
                    name: name,
                    icon: icon,
                    colorHex: colorHex,
                    sortOrder: values.count,
                    dimension: dimension
                )
                try repositories.categoryValue.insertAndSave(model)
            }
            loadData()
            return true
        } catch {
            repositories.categoryValue.rollbackContext()
            SnapDrillLogger.generic.error("保存维度值失败: \(error.localizedDescription)")
            operationError = L10n.Errors.saveFailed
            return false
        }
    }

    // MARK: - Private

    /// 持久化单值/多值变更（内置维度禁改）
    private func persistMultiValue() {
        guard !dimension.isBuiltIn else { return }
        dimension.isMultiValue = isMultiValue
        do {
            try repositories.dimension.saveContext()
        } catch {
            repositories.dimension.rollbackContext()
            SnapDrillLogger.generic.error("保存维度单值/多值开关失败: \(error.localizedDescription)")
            operationError = L10n.Errors.saveFailed
        }
    }
}
