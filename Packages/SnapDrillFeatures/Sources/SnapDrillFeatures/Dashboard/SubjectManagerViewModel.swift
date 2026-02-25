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
    
    // MARK: - Dependencies
    
    private let repository: SubjectRepositoryProtocol
    
    // MARK: - Initialization
    
    public init(repository: SubjectRepositoryProtocol = DefaultRepositoryContainer().subject) {
        self.repository = repository
    }
    
    // MARK: - Public Actions
    
    public func loadData() {
        do {
            subjects = try repository.fetchAll().sorted(by: { $0.sortOrder < $1.sortOrder })
        } catch {
            SnapDrillLogger.generic.error("Failed to load subjects: \(error)")
        }
    }
    
    public func delete(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { subjects[$0] }
        for item in itemsToDelete {
            repository.delete(item)
        }
        loadData()
    }
    
    public func saveSubject(subject: SubjectModel?, name: String, selectedIcon: String, finalColorHex: String) {
        if let subject {
            do {
                try repository.update(subject, name: name, icon: selectedIcon, colorHex: finalColorHex)
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to update subject: \(error)")
            }
        } else {
            do {
                try repository.add(name: name, icon: selectedIcon, colorHex: finalColorHex)
                loadData()
            } catch {
                SnapDrillLogger.generic.error("Failed to add subject: \(error)")
            }
        }
    }
}
