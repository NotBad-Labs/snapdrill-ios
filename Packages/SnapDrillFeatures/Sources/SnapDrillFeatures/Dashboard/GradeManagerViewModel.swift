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

@Observable
@MainActor
public final class GradeManagerViewModel {

    // MARK: - Properties

    public var grades: [GradeModel] = []
    public var isDeletingInUse = false
    public var pendingDeletionName = ""

    // MARK: - Dependencies

    private let repositories: RepositoryContainer

    // MARK: - Initialization

    public init(repositories: RepositoryContainer) {
        self.repositories = repositories
    }

    // MARK: - Public API

    public func loadData() {
        grades = (try? repositories.grade.fetchAllModels().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }

    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { grades[$0] }
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

    public func saveGrade(grade: GradeModel?, name: String) {
        do {
            if let grade {
                let oldName = grade.name
                if oldName != name {
                    try repositories.review.updateGradeUsage(from: oldName, to: name)
                }
                grade.name = name
                try repositories.grade.saveContext()
            } else {
                let sortOrder = try repositories.grade.totalCount()
                let model = GradeModel(name: name, sortOrder: sortOrder)
                try repositories.grade.insertAndSave(model)
            }
            loadData()
        } catch {
            SnapDrillLogger.generic.error("保存年级失败: \(error.localizedDescription)")
        }
    }
}
