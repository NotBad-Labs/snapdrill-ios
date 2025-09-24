// NotBadTests/AppConfigurationEdgeTests.swift
// Edge and invariant tests to strengthen coverage for AppConfiguration.

import XCTest
@testable import NotBad

final class AppConfigurationEdgeTests: XCTestCase {
    func testValidateConfiguration_isValidWithCurrentDefaults() {
        let result = AppConfiguration.validateConfiguration()
        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.issues.isEmpty)
        XCTAssertTrue(result.description.hasPrefix("✅"))
    }

    func testConfigurationValidationResult_description_invalidListsIssues() {
        let result = ConfigurationValidationResult(isValid: false, issues: ["A 问题", "B 问题"])
        let desc = result.description
        XCTAssertTrue(desc.hasPrefix("❌"))
        XCTAssertTrue(desc.contains("• A 问题"))
        XCTAssertTrue(desc.contains("• B 问题"))
    }

    func testFeaturesFlags_inDebugBuild() {
        // Expectations under DEBUG build
        #if DEBUG
        XCTAssertTrue(AppConfiguration.Features.enableAdvancedLogging)
        XCTAssertFalse(AppConfiguration.Features.enableCrashReporting)
        #else
        // On non-DEBUG builds, just assert they are Bools (smoke) to execute code paths
        _ = AppConfiguration.Features.enableAdvancedLogging
        _ = AppConfiguration.Features.enableCrashReporting
        #endif
        XCTAssertTrue(AppConfiguration.Features.enablePerformanceMonitoring)
        XCTAssertTrue(AppConfiguration.Features.enableAnalytics)
    }

    func testEnvironment_currentAndBooleansConsistency() {
        let env = AppConfiguration.Environment.current
        // Must be one of known cases
        XCTAssertTrue(AppConfiguration.Environment.EnvironmentType.allCases.contains(env))
        // Boolean helpers consistent with case
        switch env {
        case .development:
            XCTAssertTrue(env.isDevelopment)
            XCTAssertFalse(env.isProduction)
            XCTAssertEqual(env.displayName, "Development")
        case .staging:
            XCTAssertFalse(env.isDevelopment)
            XCTAssertFalse(env.isProduction)
            XCTAssertEqual(env.displayName, "Staging")
        case .production:
            XCTAssertFalse(env.isDevelopment)
            XCTAssertTrue(env.isProduction)
            XCTAssertEqual(env.displayName, "Production")
        }
    }

    func testLifecycleAndPerformanceInvariants_hold() {
        // Invariants implied by validateConfiguration()
        XCTAssertGreaterThanOrEqual(AppConfiguration.Lifecycle.Launch.minimumDisplayTime, 0)
        XCTAssertGreaterThanOrEqual(AppConfiguration.Lifecycle.Launch.initializationTimeout, AppConfiguration.Lifecycle.Launch.minimumDisplayTime)
        XCTAssertGreaterThanOrEqual(AppConfiguration.Lifecycle.Performance.maxConcurrentOperations, 1)
        XCTAssertGreaterThanOrEqual(AppConfiguration.Lifecycle.Performance.cacheLimit, 0)
    }

    func testDebugDescription_containsKeySections_whenDebug() {
        #if DEBUG
        let text = AppConfiguration.debugDescription()
        XCTAssertTrue(text.contains("UI Configuration"))
        XCTAssertTrue(text.contains("Launch Display Time"))
        XCTAssertTrue(text.contains("Advanced Logging"))
        XCTAssertTrue(text.contains("Environment:"))
        #else
        // Ensure the test compiles on non-DEBUG; no-op
        XCTAssertTrue(true)
        #endif
    }
}
