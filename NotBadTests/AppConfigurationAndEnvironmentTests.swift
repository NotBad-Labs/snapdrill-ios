//
//  AppConfigurationAndEnvironmentTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

final class AppConfigurationAndEnvironmentTests: XCTestCase {
    func testAppConfigurationValidation_IsValidWithDefaults() {
        let result = AppConfiguration.validateConfiguration()
        XCTAssertTrue(result.isValid)
        XCTAssertEqual(result.issues.count, 0)
        // debug description should be non-empty in DEBUG configuration
        #if DEBUG
        let desc = AppConfiguration.debugDescription()
        XCTAssertTrue(desc.contains("NotBad App Configuration Debug Info"))
        #endif
    }

    @MainActor
    func testAppEnvironment_CreateAndValidate() async {
        let env = AppEnvironment.createTestEnvironment()
        let validation = env.validateEnvironment()
        XCTAssertTrue(validation.isValid)
        XCTAssertEqual(validation.issues.count, 0)
        // Ensure environment wires important singletons
        XCTAssertNotNil(env.serviceContainer.reviewItemServicing as? ReviewItemService)
        XCTAssertNotNil(env.startupManager.initializationService as? AppInitializationService)
    }
}
