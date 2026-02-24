//
//  DashboardViewModel.swift
//  SnapDrillFeatures
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import Foundation
import Observation
import SwiftData
import SnapDrillCore
import SnapDrillData

@Observable
@MainActor
public final class DashboardViewModel {
    
    // MARK: - State
    
    public var showingSubjectManager = false
    public var showingComingSoon = false
    public var showingDraftAlert = false
    
    public init() {}
    
    // MARK: - Public API
    
    public func loadData(modelContext: ModelContext) {
        let subjectRepo = SubjectRepository(modelContext: modelContext)
        subjectRepo.initializeDefaultsIfNeeded()
    }
    
    public func checkDraftAndCapture(router: DashboardRouter) {
        if CaptureDraftService.shared.hasDraft {
            showingDraftAlert = true
        } else {
            router.navigateToCapture()
        }
    }
    
    public func startNewCapture(router: DashboardRouter) {
        CaptureDraftService.shared.clearDraft()
        router.navigateToCapture()
    }
    
    public func restoreDraft(router: DashboardRouter) {
        if let draft = CaptureDraftService.shared.loadDraft() {
            router.navigateToCapture(withDraft: draft)
        } else {
            router.navigateToCapture()
        }
    }
}
