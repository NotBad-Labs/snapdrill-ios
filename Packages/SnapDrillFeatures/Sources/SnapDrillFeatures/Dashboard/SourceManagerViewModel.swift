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
    
    // MARK: - Dependencies
    
    private let repository: SourceRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: SourceRepositoryProtocol = DefaultRepositoryContainer().source) {
        self.repository = repository
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
        let itemsToDelete = offsets.map { sources[$0] }
        for item in itemsToDelete {
            repository.delete(item)
        }
        loadData()
    }
    
    public func saveSource(source: SourceModel?, name: String, selectedIcon: String, finalColorHex: String) {
        if let source {
            // Edit mode (assuming repo has update method, will verify/add)
            do {
                try repository.update(source, name: name, icon: selectedIcon, colorHex: finalColorHex)
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to update source: \(error)")
            }
        } else {
            // Add mode
            do {
                try repository.add(name: name, icon: selectedIcon, colorHex: finalColorHex)
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to add source: \(error)")
            }
        }
    }
}
