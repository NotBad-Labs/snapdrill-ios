//
//  SettingsViewModel.swift
//  SnapDrillFeatures
//
//  Created by NotBad Labs on 2026/02/25.
//  Copyright © 2026 NotBad Labs L.L.C. All rights reserved.
//

import SwiftUI
import SwiftData
import Observation
import SnapDrillCore
import SnapDrillDomain
import SnapDrillData // Keep for DataSeeder/ModelContainer debug tool

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
    
    /// 注意：DataSeeder 属于底层调试工具，仍需 Container
    public func generateMockData(count: Int, container: SwiftData.ModelContainer) async throws -> TimeInterval {
        let seeder = DataSeeder(container: container)
        return try await seeder.seedReviewItems(count: count)
    }
}
