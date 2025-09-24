//
//  ViewRenderingEvenMoreSmokeTests.swift
//  NotBadTests
//
//  Created by Copilot on 2025/09/23.
//

import XCTest
import SwiftUI
import UIKit
@testable import NotBad

@MainActor
final class ViewRenderingEvenMoreSmokeTests: XCTestCase {

    func testContentView_Renders() {
        let view = ContentView()
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testDiscoveryView_Renders() {
        let coordinator = DiscoveryCoordinator()
        let view = DiscoveryView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testLibraryView_Renders() {
        let coordinator = LibraryCoordinator()
        let repo = InMemoryReviewItemRepository()
        let service = ReviewItemService(repository: repo)
        let vm = LibraryViewModel(reviewItemService: service, coordinator: coordinator)
        let view = LibraryView(viewModel: vm, coordinator: coordinator)
            .withAppEnvironment(AppEnvironment.createTestEnvironment())
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testCaptureView_Renders() {
        let coordinator = CaptureCoordinator()
        let view = CaptureView(coordinator: coordinator)
            .withAppEnvironment(AppEnvironment.createTestEnvironment())
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testProfileView_Renders() {
        let coordinator = ProfileCoordinator()
        let view = ProfileView(coordinator: coordinator)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }

    func testPhotoLibraryView_Renders_EmptyState() {
        let captureCoordinator = CaptureCoordinator()
        let vm = CaptureViewModel(
            captureUseCase: ServiceContainer.shared.captureReviewItemUseCase,
            coordinator: captureCoordinator
        )
        // configure error handler from test environment to avoid nils
        vm.configure(errorHandler: AppEnvironment.createTestEnvironment().errorHandler)
        let view = PhotoLibraryView(viewModel: vm)
        let hosting = UIHostingController(rootView: view)
        XCTAssertNotNil(hosting.view)
        hosting.view.setNeedsLayout()
        hosting.view.layoutIfNeeded()
    }
}
