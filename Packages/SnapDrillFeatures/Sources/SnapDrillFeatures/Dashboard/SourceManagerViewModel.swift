//
//  SourceManagerViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import Foundation
import Observation
import SnapDrillDomain
import SnapDrillCore

@Observable
@MainActor
public final class SourceManagerViewModel {
    
    // MARK: - State
    
    public var sources: [Source] = []
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
        sources = (try? taxonomyUseCase.getSources().sorted(by: { $0.sortOrder < $1.sortOrder })) ?? []
    }
    
    // MARK: - Public API
    
    public func delete(at offsets: IndexSet) {
        isDeletingInUse = false
        let itemsToDelete = offsets.map { sources[$0] }
        for item in itemsToDelete {
            do {
                if try !taxonomyUseCase.canDeleteSource(name: item.name) {
                    isDeletingInUse = true
                    pendingDeletionName = item.name
                    continue
                }
                try taxonomyUseCase.deleteSource(name: item.name)
            } catch {
                SnapDrillLogger.generic.error("删除来源失败: \(error.localizedDescription)")
            }
        }
        loadData()
    }
    
    public func saveSource(source: Source?, name: String, selectedIcon: String, finalColorHex: String) {
        do {
            if let source {
                try taxonomyUseCase.updateSource(
                    oldName: source.name,
                    newName: name,
                    icon: selectedIcon,
                    colorHex: finalColorHex
                )
            } else {
                try taxonomyUseCase.addSource(
                    name: name,
                    icon: selectedIcon,
                    colorHex: finalColorHex
                )
            }
            loadData()
        } catch {
            SnapDrillLogger.generic.error("保存来源失败: \(error.localizedDescription)")
        }
    }
}
