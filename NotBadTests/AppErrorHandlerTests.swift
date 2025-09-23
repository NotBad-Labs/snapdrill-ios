//
//  AppErrorHandlerTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

@MainActor
final class AppErrorHandlerTests: XCTestCase {
    func testHandle_AppInitializationError_setsCriticalSeverityAndCurrentError() async {
        // Given
        let handler = AppErrorHandler()
        let error = AppInitializationError.databaseInitializationFailed

        // When
        handler.handle(error)

        // Then
        let current = handler.currentError
        XCTAssertNotNil(current)
        XCTAssertEqual(current?.message, error.localizedDescription)
        XCTAssertEqual(current?.severity, .critical)
    }

    func testPresent_withWarning_setsCurrentError() async {
        // Given
        let handler = AppErrorHandler()

        // When
        handler.present(message: "Something happened", severity: .warning)

        // Then
        XCTAssertNotNil(handler.currentError)
        XCTAssertEqual(handler.currentError?.message, "Something happened")
        XCTAssertEqual(handler.currentError?.severity, .warning)

        // And when clearing
        handler.clearError()
        XCTAssertNil(handler.currentError)
    }

    func testPresent_withInfo_doesNotSetCurrentError() async {
        // Given
        let handler = AppErrorHandler()

        // When
        handler.present(message: "FYI only", severity: .info)

        // Then: info severity is logged but not surfaced to UI
        XCTAssertNil(handler.currentError)
    }
}
