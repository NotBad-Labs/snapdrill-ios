//
//  SubjectManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  学科管理 ViewModel，负责学科的增删改查与使用校验。
//

import Foundation
import Observation
import SnapDrillData
import SnapDrillCore

/// 学科管理 ViewModel
///
/// 负责学科列表的加载、新增、编辑和删除（含使用中校验）。
@Observable
public final class SubjectManagerViewModel {

    // MARK: - State

    /// 当前学科列表（按 sortOrder 排序）
    public var subjects: [SubjectModel] = []
    /// 是否因学科被使用而阻止删除
    public var isDeletingInUse = false
    /// 触发删除保护时正在尝试删除的学科名称
    public var pendingDeletionName = ""
    /// 是否因重命名目标名称已存在而阻止保存
    public var isDuplicateName = false
    /// 触发重名保护时的目标名称
    public var duplicateNameValue = ""
    /// 保存失败时展示给 UI 的错误信息
    public var operationError: String?

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - Initialization

    /// 创建学科管理 ViewModel
    /// - Parameter repositories: 应用的数据仓库容器
    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public Actions

    /// 从数据库加载学科列表
    public func loadData() {
        do {
            subjects = try repositories.subject.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.data.error("加载学科列表失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

    /// 删除指定位置的学科；若学科仍被题目引用，置 `isDeletingInUse` 为 `true`
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.compactMap { index in
            subjects.indices.contains(index) ? subjects[index] : nil
        }
        for item in itemsToDelete {
            do {
                let count = try repositories.review.countBySubject(name: item.name)
                if count > 0 {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try repositories.subject.delete(id: item.id)
            } catch {
                SnapDrillLogger.generic.error("删除学科失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }

    /// 新建或更新学科
    /// - Parameters:
    ///   - subject: 传入现有 `SubjectModel` 表示编辑，传 `nil` 表示新建
    ///   - name: 学科名称
    ///   - selectedIcon: SF Symbol 图标名称
    ///   - finalColorHex: 颜色 Hex 字符串
    /// - Returns: 保存是否成功（重名时返回 `false`，View 层据此决定是否 dismiss）
    @discardableResult
    public func saveSubject(subject: SubjectModel?, name: String, selectedIcon: String, finalColorHex: String) -> Bool {
        isDuplicateName = false
        operationError = nil
        do {
            if let subject {
                let oldName = subject.name
                if oldName != name {
                    // 检查目标名称是否已被其他学科占用
                    if let existing = try repositories.subject.fetchModel(byName: name), existing.id != subject.id {
                        isDuplicateName = true
                        duplicateNameValue = name
                        return false
                    }
                    try repositories.review.updateSubjectUsage(from: oldName, to: name)
                }
                subject.name = name
                subject.icon = selectedIcon
                subject.colorHex = finalColorHex
                try repositories.subject.saveContext()
            } else {
                // 新建时也检查重名
                if (try repositories.subject.fetchModel(byName: name)) != nil {
                    isDuplicateName = true
                    duplicateNameValue = name
                    return false
                }
                let sortOrder = try repositories.subject.totalCount()
                let model = SubjectModel(name: name, icon: selectedIcon, colorHex: finalColorHex, sortOrder: sortOrder)
                try repositories.subject.insertAndSave(model)
            }
            loadData()
            return true
        } catch {
            // 回滚所有未持久化变更（含级联重命名的内存修改），防止脏数据污染 mainContext
            repositories.subject.rollbackContext()
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("保存学科失败: \(error.localizedDescription)")
            operationError = L10n.Errors.saveFailed
            return false
        }
    }
}
