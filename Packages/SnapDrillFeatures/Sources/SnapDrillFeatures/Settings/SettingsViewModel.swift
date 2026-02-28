//
//  SettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import Observation
import SnapDrillCore
import SnapDrillDomain

@Observable
@MainActor
public final class SettingsViewModel {
    private let reviewUseCase: ReviewUseCaseProtocol
    private let taxonomyUseCase: TaxonomyUseCaseProtocol
    
    // MARK: - Initialization
    
    public init(
        reviewUseCase: ReviewUseCaseProtocol,
        taxonomyUseCase: TaxonomyUseCaseProtocol
    ) {
        self.reviewUseCase = reviewUseCase
        self.taxonomyUseCase = taxonomyUseCase
    }
    
    // MARK: - Public API
    
    public func clearAllData() {
        do {
            try reviewUseCase.deleteAllData()
            try taxonomyUseCase.deleteAllTaxonomy()
            
            SnapDrillLogger.generic.info("Successfully cleared all data via logic layer.")
        } catch {
            SnapDrillLogger.generic.error("Failed to clear data: \(error)")
        }
    }
    
}
