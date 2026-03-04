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

@Observable
@MainActor
public final class SubjectManagerViewModel {

    // MARK: - State

    public var subjects: [SubjectModel] = []
    public var isDeletingInUse = false
    public var pendingDeletionName = ""

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - Initialization

    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public Actions

    public func loadData() {
        do {
            subjects = try repositories.subject.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.data.error("加载学科列表失败: \(error.localizedDescription)")
        }
    }

    // MARK: - Public API

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
            SnapDrillLogger.generic.error("保存学科失败: \(error.localizedDescription)")
        }
    }
}
