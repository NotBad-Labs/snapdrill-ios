//
//  SettingsViewModel.swift
//  SnapDrillFeatureSettings
//
//  Created by SnapDrill Architect on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import SwiftUI
import SwiftData
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class SettingsViewModel {
    private let reviewRepo: ReviewRepositoryProtocol
    private let subjectRepo: SubjectRepositoryProtocol
    private let sourceRepo: SourceRepositoryProtocol
    private let tagRepo: TagRepositoryProtocol
    
    public init(
        reviewRepo: ReviewRepositoryProtocol,
        subjectRepo: SubjectRepositoryProtocol,
        sourceRepo: SourceRepositoryProtocol,
        tagRepo: TagRepositoryProtocol
    ) {
        self.reviewRepo = reviewRepo
        self.subjectRepo = subjectRepo
        self.sourceRepo = sourceRepo
        self.tagRepo = tagRepo
    }
    
    public func clearAllData() {
            try reviewRepo.deleteAll()
            try subjectRepo.deleteAll()
            try sourceRepo.deleteAll()
            
            // Re-init defaults
            subjectRepo.initializeDefaultsIfNeeded()
            sourceRepo.seedDefaultSourcesIfNeeded()
            
            reviewRepo.save()
            SnapDrillLogger.generic.info("Successfully cleared all data and re-seeded defaults.")
        } catch {
            SnapDrillLogger.generic.error("Failed to clear data: \(error)")
        }
    }
    
    public func generateMockData(count: Int, container: ModelContainer) async throws -> TimeInterval {
        let seeder = DataSeeder(container: container)
        let time = try await seeder.seedReviewItems(count: count)
        // Ensure consistency after background seeding
        try await Task { @MainActor in
            try? reviewRepo.save()
        }.value
        return time
    }
}
