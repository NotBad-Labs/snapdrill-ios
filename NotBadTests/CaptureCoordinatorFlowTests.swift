//
//  CaptureCoordinatorFlowTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

@MainActor
final class CaptureCoordinatorFlowTests: XCTestCase {
    private final class SpyParentCoordinator: BaseCoordinator {
        var routed: [Route] = []
        override func coordinate(to route: Route) {
            routed.append(route)
        }
    }

    func testCompleteWorkflow_RoutesReturnToLibrary() {
        let parent = SpyParentCoordinator()
        let coordinator = CaptureCoordinator()
        coordinator.parent = parent

        coordinator.completeWorkflow(nextAction: .returnToLibrary)

        XCTAssertEqual(parent.routed.last, .navigateToLibraryAfterCapture)
    }

    func testCompleteWorkflow_RoutesStartPractice() {
        let parent = SpyParentCoordinator()
        let coordinator = CaptureCoordinator()
        coordinator.parent = parent

        coordinator.completeWorkflow(nextAction: .startPractice)

        XCTAssertEqual(parent.routed.last, .navigateToPracticeFromLibrary)
    }

    func testCompleteWorkflow_AddAnotherResetsState() {
        let parent = SpyParentCoordinator()
        let coordinator = CaptureCoordinator()
        coordinator.parent = parent

        coordinator.showCamera = true
        coordinator.showPhotoLibrary = true
        coordinator.navigationPath.append("dummy")

        coordinator.completeWorkflow(nextAction: .addAnother)

        XCTAssertFalse(coordinator.showCamera)
        XCTAssertFalse(coordinator.showPhotoLibrary)
        XCTAssertEqual(coordinator.navigationPath.count, 0)
    }

    func testGoBack_ClosesSheetsBeforePopping() {
        let coordinator = CaptureCoordinator()

        coordinator.showCamera = true
        coordinator.showPhotoLibrary = false
        coordinator.goBack()
        XCTAssertFalse(coordinator.showCamera)

        coordinator.showPhotoLibrary = true
        coordinator.goBack()
        XCTAssertFalse(coordinator.showPhotoLibrary)
    }
}
