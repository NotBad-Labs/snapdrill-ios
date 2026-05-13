//
//  GradeManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/03/01.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//
//  年级管理 ViewModel，与 SubjectManagerViewModel 对等。
//

import Foundation
import Observation
import SnapDrillData
import SnapDrillCore

/// 年级管理 ViewModel
///
/// 负责年级列表的加载、新增、编辑和删除（含使用中校验）。与 `SubjectManagerViewModel` 结构对等。
@Observable
public final class GradeManagerViewModel {

    // MARK: - Properties

    /// 当前年级列表（按 sortOrder 排序）
    public var grades: [GradeModel] = []
    /// 是否因年级被使用而阻止删除
    public var isDeletingInUse = false
    /// 触发删除保护时正在尝试删除的年级名称
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

    /// 创建年级管理 ViewModel
    /// - Parameter repositories: 应用的数据仓库容器
    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    /// 从数据库加载年级列表
    public func loadData() {
        do {
            grades = try repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.data.error("加载年级列表失败: \(error.localizedDescription)")
        }
    }

    /// 删除指定位置的年级；若年级仍被题目引用，置 `isDeletingInUse` 为 `true`
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.compactMap { index in
            grades.indices.contains(index) ? grades[index] : nil
        }
        for item in itemsToDelete {
            do {
                let count = try repositories.review.countByGrade(name: item.name)
                if count > 0 {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try repositories.grade.delete(id: item.id)
            } catch {
                SnapDrillLogger.generic.error("删除年级失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }

    /// 新建或更新年级
    /// - Parameters:
    ///   - grade: 传入现有 `GradeModel` 表示编辑，传 `nil` 表示新建
    ///   - name: 年级名称
    /// - Returns: 保存是否成功（重名时返回 `false`，View 层据此决定是否 dismiss）
    @discardableResult
    public func saveGrade(grade: GradeModel?, name: String) -> Bool {
        isDuplicateName = false
        operationError = nil
        do {
            if let grade {
                let oldName = grade.name
                if oldName != name {
                    if let existing = try repositories.grade.fetchModel(byName: name), existing.id != grade.id {
                        isDuplicateName = true
                        duplicateNameValue = name
                        return false
                    }
                    try repositories.review.updateGradeUsage(from: oldName, to: name)
                }
                grade.name = name
                try repositories.grade.saveContext()
            } else {
                if (try repositories.grade.fetchModel(byName: name)) != nil {
                    isDuplicateName = true
                    duplicateNameValue = name
                    return false
                }
                let sortOrder = try repositories.grade.totalCount()
                let model = GradeModel(name: name, sortOrder: sortOrder)
                try repositories.grade.insertAndSave(model)
            }
            loadData()
            return true
        } catch {
            repositories.grade.rollbackContext()
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("保存年级失败: \(error.localizedDescription)")
            operationError = L10n.Errors.saveFailed
            return false
        }
    }
}
