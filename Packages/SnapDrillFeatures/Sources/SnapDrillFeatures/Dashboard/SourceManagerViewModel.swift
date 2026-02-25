//
//  SourceManagerViewModel.swift
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
public final class SourceManagerViewModel {
    
    // MARK: - State
    
    public var sources: [SourceModel] = []
    public var isDeletingInUse = false
    public var pendingDeletionName = ""
    
    // MARK: - Dependencies
    
    private let repository: SourceRepositoryProtocol
    private let reviewRepository: ReviewRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(
        repository: SourceRepositoryProtocol = DefaultRepositoryContainer().source,
        reviewRepository: ReviewRepositoryProtocol = DefaultRepositoryContainer().review
    ) {
        self.repository = repository
        self.reviewRepository = reviewRepository
    }
    
    // MARK: - Public Actions
    
    public func loadData() {
        do {
            repository.seedDefaultSourcesIfNeeded()
            sources = try repository.fetchAll().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.generic.error("Failed to load sources: \(error)")
        }
    }
    
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { sources[$0] }
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
                SnapDrillLogger.generic.error("Failed to delete source: \(error)")
            }
        }
        loadData()
    }
    
    public func saveSource(source: SourceModel?, name: String, selectedIcon: String, finalColorHex: String) {
        if let source {
            let oldName = source.name
            do {
                if oldName != name {
                    // CASCADING RENAME
                    try reviewRepository.updateSourceUsage(from: oldName, to: name)
                }
                try repository.update(source, name: name, icon: selectedIcon, colorHex: finalColorHex)
                try repository.save()
                try reviewRepository.save()
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to update source: \(error)")
            }
        } else {
            do {
                try repository.add(name: name, icon: selectedIcon, colorHex: finalColorHex)
                try repository.save()
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to add source: \(error)")
            }
        }
    }
}
