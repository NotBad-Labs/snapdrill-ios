//
//  ViewRenderingTinyExtrasTests.swift
//  NotBadTests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class ViewRenderingTinyExtrasTests: XCTestCase {

    func testDiscovery_Subviews_Render() {
        let coordinator = DiscoveryCoordinator()
        let discoveryContent = DiscoveryContentView(coordinator: coordinator)
        let featuresSection = DiscoveryFeaturesSection(coordinator: coordinator)
        let featuresGrid = DiscoveryFeaturesGrid(coordinator: coordinator)
        let resources = DiscoveryResourcesSection(coordinator: coordinator)

        _ = UIHostingController(rootView: discoveryContent).view
        _ = UIHostingController(rootView: featuresSection).view
        _ = UIHostingController(rootView: featuresGrid).view
        _ = UIHostingController(rootView: resources).view
    }

    func testProfile_Subviews_Render() {
        let coordinator = ProfileCoordinator()
        let content = ProfileContentView(coordinator: coordinator)
        let header = ProfileHeaderSection()
        let stats = ProfileStatsSection()
        let menu = ProfileMenuSection(coordinator: coordinator)

        _ = UIHostingController(rootView: content).view
        _ = UIHostingController(rootView: header).view
        _ = UIHostingController(rootView: stats).view
        _ = UIHostingController(rootView: menu).view
    }

    func testHome_Subviews_Render() {
        _ = UIHostingController(rootView: HomeWelcomeView()).view
        _ = UIHostingController(rootView: HomeStatsView()).view
        _ = UIHostingController(rootView: HomeRecentActivityView()).view
    }

    func testCapture_Subviews_Render() {
        let header = CaptureHeaderView()
        let vm = CaptureViewModel(captureUseCase: ServiceContainer.shared.captureReviewItemUseCase, coordinator: CaptureCoordinator())
        // Configure error handler to avoid nil optional paths
        vm.configure(errorHandler: AppEnvironment.createTestEnvironment().errorHandler)
        let options = CaptureOptionsView(viewModel: vm)

        _ = UIHostingController(rootView: header).view
        _ = UIHostingController(rootView: options).view
        // Also exercise an option button in isolation
        let button = CaptureOptionButton(icon: "doc.text.viewfinder", title: "扫描", color: .green, action: {})
        _ = UIHostingController(rootView: button).view
    }

    func testLibraryStatCard_Renders() {
        let card = LibraryStatCard(title: "总题数", count: 0, color: .blue)
        _ = UIHostingController(rootView: card).view
    }
}
