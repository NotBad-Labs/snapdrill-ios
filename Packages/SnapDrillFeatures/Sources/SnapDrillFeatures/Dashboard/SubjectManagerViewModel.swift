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
import SnapDrillDomain
import SnapDrillCore

@Observable
@MainActor
public final class SubjectManagerViewModel {
    
    // MARK: - State
    
    public var subjects: [Subject] = []
    public var isDeletingInUse = false
    public var pendingDeletionName = ""
    
    // MARK: - Dependencies
    
    private let taxonomyUseCase: TaxonomyUseCaseProtocol
    
    // MARK: - Initialization
    
    public init(taxonomyUseCase: TaxonomyUseCaseProtocol) {
        self.taxonomyUseCase = taxonomyUseCase
    }
    
    // MARK: - Public Actions
    
    public func loadData() {
        subjects = (try? taxonomyUseCase.getSubjects().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }
    
    // MARK: - Public API
    
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { subjects[$0] }
        for item in itemsToDelete {
            do {
                if try !taxonomyUseCase.canDeleteSubject(name: item.name) {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try taxonomyUseCase.deleteSubject(name: item.name)
            } catch {
                SnapDrillLogger.generic.error("删除学科失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }
    
    public func saveSubject(subject: Subject?, name: String, selectedIcon: String, finalColorHex: String) {
        do {
            if let subject {
                try taxonomyUseCase.updateSubject(
                    oldName: subject.name,
                    newName: name,
                    icon: selectedIcon,
                    colorHex: finalColorHex
                )
            } else {
                try taxonomyUseCase.addSubject(
                    name: name,
                    icon: selectedIcon,
                    colorHex: finalColorHex
                )
            }
            loadData()
        } catch {
            SnapDrillLogger.generic.error("保存学科失败: \(error.localizedDescription)")
        }
    }
}
