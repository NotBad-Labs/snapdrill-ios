//
//  CoordinatorEdgeCaseTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class CoordinatorEdgeCaseTests: XCTestCase {
    // MARK: - Mocks
    final class MockParentCoordinator: BaseCoordinator {
        private(set) var lastRoute: Route?
        override func coordinate(to route: Route) {
            lastRoute = route
        }
    }

    // MARK: - CaptureCoordinator edge cases
    func testCaptureCoordinator_PresentCameraAndPhotoLibrary_ThenGoBack() {
        let coordinator = CaptureCoordinator()
        coordinator.start()

        // Present camera
        coordinator.coordinate(to: .camera)
        XCTAssertTrue(coordinator.showCamera)
        coordinator.goBack() // should close camera sheet first
        XCTAssertFalse(coordinator.showCamera)

        // Present photo library
        coordinator.coordinate(to: .photoLibrary)
        XCTAssertTrue(coordinator.showPhotoLibrary)
        coordinator.goBack() // should close photo library sheet first
        XCTAssertFalse(coordinator.showPhotoLibrary)

        // Push OCR route then goBack should pop path
        XCTAssertEqual(coordinator.navigationPath.count, 0)
        coordinator.coordinate(to: .ocrResult(image: "base64"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        coordinator.goBack()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testCaptureCoordinator_CompleteWorkflow_DelegatesRoutes() {
        let parent = MockParentCoordinator()
        let coordinator = CaptureCoordinator()
        coordinator.parent = parent

        coordinator.completeWorkflow(nextAction: .returnToLibrary)
        XCTAssertEqual(parent.lastRoute, .navigateToLibraryAfterCapture)

        coordinator.completeWorkflow(nextAction: .startPractice)
        XCTAssertEqual(parent.lastRoute, .navigateToPracticeFromLibrary)

        // .addAnother should not delegate, it resets capture flow locally
    let beforeRoute = parent.lastRoute
        coordinator.completeWorkflow(nextAction: .addAnother)
    XCTAssertEqual(parent.lastRoute, beforeRoute)
    }

    // MARK: - Home delegation
    func testHomeCoordinator_DelegatesCrossTabRouteToParent() {
        let parent = MockParentCoordinator()
        let coordinator = HomeCoordinator()
        coordinator.parent = parent

        coordinator.coordinate(to: .navigateToLibraryFromHome)
        XCTAssertEqual(parent.lastRoute, .navigateToLibraryFromHome)
    }

    // MARK: - Library goBack
    func testLibraryCoordinator_GoBack_PopsOneRoute() {
        let coordinator = LibraryCoordinator()
        coordinator.start()
        XCTAssertEqual(coordinator.navigationPath.count, 0)

        coordinator.coordinate(to: .detail(module: "library", id: "1"))
        XCTAssertEqual(coordinator.navigationPath.count, 1)
        coordinator.goBack()
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }
}
