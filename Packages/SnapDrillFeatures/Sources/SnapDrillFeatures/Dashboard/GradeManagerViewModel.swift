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
import SnapDrillDomain
import SnapDrillCore

@Observable
@MainActor
public final class GradeManagerViewModel {

    // MARK: - Properties

    public var grades: [Grade] = []
    public var isDeletingInUse = false
    public var pendingDeletionName = ""

    // MARK: - Dependencies

    private let taxonomyUseCase: TaxonomyUseCaseProtocol

    // MARK: - Initialization

    public init(taxonomyUseCase: TaxonomyUseCaseProtocol) {
        self.taxonomyUseCase = taxonomyUseCase
    }

    // MARK: - Public API

    public func loadData() {
        grades = (try? taxonomyUseCase.getGrades().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }

    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { grades[$0] }
        for item in itemsToDelete {
            do {
                if try !taxonomyUseCase.canDeleteGrade(name: item.name) {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try taxonomyUseCase.deleteGrade(name: item.name)
            } catch {
                SnapDrillLogger.generic.error("删除年级失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }

    public func saveGrade(grade: Grade?, name: String) {
        do {
            if let grade {
                try taxonomyUseCase.updateGrade(oldName: grade.name, newName: name)
            } else {
                try taxonomyUseCase.addGrade(name: name)
            }
            loadData()
        } catch {
            SnapDrillLogger.generic.error("保存年级失败: \(error.localizedDescription)")
        }
    }
}
