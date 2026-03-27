//
//  SourceManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  来源管理 ViewModel，负责来源的增删改查与使用校验。
//

import Foundation
import Observation
import SnapDrillData
import SnapDrillCore

/// 来源管理 ViewModel
///
/// 负责来源列表的加载、新增、编辑和删除（含使用中校验）。与 `SubjectManagerViewModel` 结构对等。
@Observable
public final class SourceManagerViewModel {

    // MARK: - State

    /// 当前来源列表（按 sortOrder 排序）
    public var sources: [SourceModel] = []
    /// 是否因来源被使用而阻止删除
    public var isDeletingInUse = false
    /// 触发删除保护时正在尝试删除的来源名称
    public var pendingDeletionName = ""
    /// 是否因重命名目标名称已存在而阻止保存
    public var isDuplicateName = false
    /// 触发重名保护时的目标名称
    public var duplicateNameValue = ""

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - Initialization

    /// 创建来源管理 ViewModel
    /// - Parameter repositories: 应用的数据仓库容器
    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public Actions

    /// 从数据库加载来源列表
    public func loadData() {
        do {
            sources = try repositories.source.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.data.error("加载来源列表失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    /// 删除指定位置的来源；若来源仍被题目引用，置 `isDeletingInUse` 为 `true`
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { sources[$0] }
        for item in itemsToDelete {
            do {
                let count = try repositories.review.countBySource(name: item.name)
                if count > 0 {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try repositories.source.delete(id: item.id)
            } catch {
                SnapDrillLogger.generic.error("删除来源失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }

    /// 新建或更新来源
    /// - Parameters:
    ///   - source: 传入现有 `SourceModel` 表示编辑，传 `nil` 表示新建
    ///   - name: 来源名称
    ///   - selectedIcon: SF Symbol 图标名称
    ///   - finalColorHex: 颜色 Hex 字符串
    /// - Returns: 保存是否成功（重名时返回 `false`，View 层据此决定是否 dismiss）
    @discardableResult
    public func saveSource(source: SourceModel?, name: String, selectedIcon: String, finalColorHex: String) -> Bool {
        isDuplicateName = false
        do {
            if let source {
                let oldName = source.name
                if oldName != name {
                    if let existing = try repositories.source.fetchModel(byName: name), existing.id != source.id {
                        isDuplicateName = true
                        duplicateNameValue = name
                        return false
                    }
                    try repositories.review.updateSourceUsage(from: oldName, to: name)
                }
                source.name = name
                source.icon = selectedIcon
                source.colorHex = finalColorHex
                try repositories.source.saveContext()
            } else {
                if (try repositories.source.fetchModel(byName: name)) != nil {
                    isDuplicateName = true
                    duplicateNameValue = name
                    return false
                }
                let sortOrder = try repositories.source.totalCount()
                let model = SourceModel(name: name, icon: selectedIcon, colorHex: finalColorHex, sortOrder: sortOrder)
                try repositories.source.insertAndSave(model)
            }
            loadData()
            return true
        } catch {
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("保存来源失败: \(error.localizedDescription)")
            return false
        }
    }
}
