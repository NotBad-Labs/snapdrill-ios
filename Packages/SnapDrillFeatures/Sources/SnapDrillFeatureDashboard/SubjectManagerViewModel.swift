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
@MainActor
public final class SubjectManagerViewModel {

    // MARK: - State

    /// 当前学科列表（按 sortOrder 排序）
    public var subjects: [SubjectModel] = []
    /// 是否因学科被使用而阻止删除
    public var isDeletingInUse = false
    /// 触发删除保护时正在尝试删除的学科名称
    public var pendingDeletionName = ""

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
        let itemsToDelete = offsets.map { subjects[$0] }
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
    public func saveSubject(subject: SubjectModel?, name: String, selectedIcon: String, finalColorHex: String) {
        do {
            if let subject {
                let oldName = subject.name
                if oldName != name {
                    try repositories.review.updateSubjectUsage(from: oldName, to: name)
                }
                subject.name = name
                subject.icon = selectedIcon
                subject.colorHex = finalColorHex
                try repositories.subject.saveContext()
            } else {
                let sortOrder = try repositories.subject.totalCount()
                let model = SubjectModel(name: name, icon: selectedIcon, colorHex: finalColorHex, sortOrder: sortOrder)
                try repositories.subject.insertAndSave(model)
            }
            loadData()
        } catch {
            // 回滚所有未持久化变更（含级联重命名的内存修改），防止脏数据污染 mainContext
            repositories.review.rollbackContext()
            SnapDrillLogger.generic.error("保存学科失败: \(error.localizedDescription)")
        }
    }
}
