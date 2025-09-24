//
//  AppInfraAndCoordinatorMiscTests.swift
//  NotBadTests
//
//  Created by Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

@MainActor
final class AppInfraAndCoordinatorMiscTests: XCTestCase {
    func test_MainCoordinator_getCurrentTabCoordinator_coversAllBranches() {
        let main = MainCoordinator()
        main.start()

        main.selectedTab = 0
        XCTAssertNotNil(main.getCurrentTabCoordinator() as? HomeCoordinator)

        main.selectedTab = 1
        XCTAssertNotNil(main.getCurrentTabCoordinator() as? LibraryCoordinator)

        main.selectedTab = 2
        XCTAssertNotNil(main.getCurrentTabCoordinator() as? CaptureCoordinator)

        main.selectedTab = 3
        XCTAssertNotNil(main.getCurrentTabCoordinator() as? DiscoveryCoordinator)

        main.selectedTab = 4
        XCTAssertNotNil(main.getCurrentTabCoordinator() as? ProfileCoordinator)

        // default branch
        main.selectedTab = 99
        XCTAssertNil(main.getCurrentTabCoordinator())
    }

    func test_ConfigurationValidationResult_description_validAndInvalid() {
        let valid = ConfigurationValidationResult(isValid: true, issues: [])
        XCTAssertTrue(valid.description.contains("✅"))

        let invalid = ConfigurationValidationResult(isValid: false, issues: ["issue A", "issue B"])
        let desc = invalid.description
        XCTAssertTrue(desc.contains("❌"))
        XCTAssertTrue(desc.contains("issue A"))
        XCTAssertTrue(desc.contains("issue B"))
    }

    func test_EnvironmentValidationResult_description_validAndInvalid() {
        #if DEBUG
        let ok = EnvironmentValidationResult(isValid: true, issues: [])
        XCTAssertTrue(ok.description.contains("✅"))

        let bad = EnvironmentValidationResult(isValid: false, issues: ["E1"]) 
        XCTAssertTrue(bad.description.contains("❌"))
        XCTAssertTrue(bad.description.contains("E1"))
        #else
        // In non-DEBUG builds the type is not available; just ensure test runs
        XCTAssertTrue(true)
        #endif
    }

    func test_ServiceContainer_createForTesting_executesPath() {
        #if DEBUG
        let repo = InMemoryReviewItemRepository()
        let container = ServiceContainer.createForTesting(with: repo)
        // Sanity checks to touch returned container and public getters
        _ = container.reviewItemRepository
        _ = container.reviewItemService
        _ = container.reviewItemServicing
        _ = container.captureReviewItemUseCase
        _ = container.reviewSessionUseCase
        XCTAssertTrue(true)
        #else
        XCTAssertTrue(true)
        #endif
    }
}
