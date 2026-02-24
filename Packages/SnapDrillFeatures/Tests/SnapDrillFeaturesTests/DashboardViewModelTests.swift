//
//  DashboardViewModelTests.swift
//  SnapDrillFeaturesTests
//
//  Created by SnapDrill Labs on 2026/02/25.
//  Copyright © 2026 SnapDrill Labs L.L.C. All rights reserved.
//

import XCTest
import SwiftData
import Testing
@testable import SnapDrillFeatures
@testable import SnapDrillCore

@MainActor
struct DashboardViewModelTests {
    
    // MARK: - Helper Methods
    
    private func cleanUpDraft() {
        CaptureDraftService.shared.clearDraft()
    }
    
    private func createTestImage() -> UIImage {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
    // MARK: - Tests
    
    @Test
    func testCheckDraftAndCapture_NoDraft_NavigatesToCapture() {
        cleanUpDraft()
        
        let viewModel = DashboardViewModel()
        let router = DashboardRouter()
        
        var navigateCalled = false
        router.onNavigateToCapture = { draft in
            navigateCalled = true
            #expect(draft == nil)
        }
        
        viewModel.checkDraftAndCapture(router: router)
        
        #expect(navigateCalled == true)
        #expect(viewModel.showingDraftAlert == false)
    }
    
    @Test
    func testCheckDraftAndCapture_HasDraft_ShowsAlert() {
        cleanUpDraft()
        CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")
        
        let viewModel = DashboardViewModel()
        let router = DashboardRouter()
        
        var navigateCalled = false
        router.onNavigateToCapture = { _ in
            navigateCalled = true
        }
        
        viewModel.checkDraftAndCapture(router: router)
        
        #expect(navigateCalled == false)
        #expect(viewModel.showingDraftAlert == true)
        
        cleanUpDraft()
    }
    
    @Test
    func testStartNewCapture_ClearsDraftAndNavigates() {
        cleanUpDraft()
        CaptureDraftService.shared.saveDraft(image: createTestImage(), content: "Draft Content")
        
        let viewModel = DashboardViewModel()
        let router = DashboardRouter()
        
        var navigateCalled = false
        router.onNavigateToCapture = { draft in
            navigateCalled = true
            #expect(draft == nil)
        }
        
        viewModel.startNewCapture(router: router)
        
        #expect(navigateCalled == true)
        #expect(CaptureDraftService.shared.hasDraft == false)
        
        cleanUpDraft()
    }
    
    @Test
    func testRestoreDraft_NavigatesWithDraft() {
        cleanUpDraft()
        let testImage = createTestImage()
        CaptureDraftService.shared.saveDraft(image: testImage, content: "Draft Content")
        
        let viewModel = DashboardViewModel()
        let router = DashboardRouter()
        
        var navigateCalled = false
        router.onNavigateToCapture = { draft in
            navigateCalled = true
            #expect(draft != nil)
            #expect(draft?.content == "Draft Content")
        }
        
        viewModel.restoreDraft(router: router)
        
        #expect(navigateCalled == true)
        
        cleanUpDraft()
    }
}
