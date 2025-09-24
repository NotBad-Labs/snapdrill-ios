//
//  AppStartupManagerCancellationTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/23/25.
//

import XCTest
@testable import NotBad

final class AppStartupManagerCancellationTests: XCTestCase {
    @MainActor
    func testStartupCancellation_ProducesTimeoutAndResetsState() async {
        // Given
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        // When: fire startup in a Task and cancel shortly after
        let task = Task { await manager.performStartup() }
        // Give it a brief moment to enter loop
        try? await Task.sleep(for: .milliseconds(50))
        task.cancel()

        // Then: await result and verify timeout path
        let result = await task.value
        XCTAssertFalse(result.success)
        XCTAssertNotNil(result.error)
        if let error = result.error as? StartupError {
            switch error {
            case .timeout: break // expected
            default: XCTFail("Expected timeout error, got: \(error)")
            }
        } else {
            XCTFail("Expected StartupError.timeout")
        }

        // State should be reset to notStarted according to code path
        XCTAssertEqual(manager.startupState, .notStarted)
        XCTAssertLessThanOrEqual(manager.progress, 1.0)
    }
}
