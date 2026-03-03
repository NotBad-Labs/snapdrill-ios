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

@Observable
@MainActor
public final class SourceManagerViewModel {

    // MARK: - State

    public var sources: [SourceModel] = []
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
        sources = (try? repositories.source.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }

    // MARK: - Public API

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

    public func saveSource(source: SourceModel?, name: String, selectedIcon: String, finalColorHex: String) {
        do {
            if let source {
                let oldName = source.name
                if oldName != name {
                    try repositories.review.updateSourceUsage(from: oldName, to: name)
                }
                source.name = name
                source.icon = selectedIcon
                source.colorHex = finalColorHex
                try repositories.source.saveContext()
            } else {
                let sortOrder = try repositories.source.totalCount()
                let model = SourceModel(name: name, icon: selectedIcon, colorHex: finalColorHex, sortOrder: sortOrder)
                try repositories.source.insertAndSave(model)
            }
            loadData()
        } catch {
            SnapDrillLogger.generic.error("保存来源失败: \(error.localizedDescription)")
        }
    }
}
