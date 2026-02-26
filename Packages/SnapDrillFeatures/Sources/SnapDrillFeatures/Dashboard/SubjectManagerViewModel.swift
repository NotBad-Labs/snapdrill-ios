//
//  SubjectManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
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
    /// 标记是否由于题目引用导致删除被屏蔽
    public var isDeletingInUse = false
    /// 待删除但受阻的名称
    public var pendingDeletionName = ""
    
    // MARK: - Dependencies
    
    private let repository: SubjectRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(
        repository: SubjectRepositoryProtocol = DefaultRepositoryContainer().subject,
        reviewRepository: ReviewRepositoryProtocol = DefaultRepositoryContainer().review
    ) {
        self.repository = repository
        self.reviewRepository = reviewRepository
    }
    
    // MARK: - Public Actions
    
    public func loadData() {
        subjects = (try? repository.fetchAll().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }
    
    // MARK: - Public API
    
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { subjects[$0] }
        for item in itemsToDelete {
            do {
                let usageCount = try repository.countItems(named: item.name)
                if usageCount > 0 {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue 
                }
                repository.delete(item)
                try repository.save()
            } catch {
                SnapDrillLogger.generic.error("Failed to delete subject: \(error)")
            }
        }
        loadData()
    }
    
    public func saveSubject(subject: SubjectModel?, name: String, selectedIcon: String, finalColorHex: String) {
        if let subject {
            let oldName = subject.name
            do {
                if oldName != name {
                    // CASCADING RENAME
                    try reviewRepository.updateSubjectUsage(from: oldName, to: name)
                }
                try repository.update(subject, name: name, icon: selectedIcon, colorHex: finalColorHex)
                try repository.save()
                try reviewRepository.save() 
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to update subject: \(error)")
            }
        } else {
            do {
                try repository.add(name: name, icon: selectedIcon, colorHex: finalColorHex)
                try repository.save()
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to add subject: \(error)")
            }
        }
    }
}
