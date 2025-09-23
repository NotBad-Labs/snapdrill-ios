//
//  AppStartupManagerMoreTests.swift
//  NotBadTests
//
//  Created by GitHub Copilot on 9/22/25.
//

import XCTest
@testable import NotBad

final class AppStartupManagerMoreTests: XCTestCase {
    @MainActor
    func testStartupFailure_InjectsError_setsFailedAndProgressNotOne() async {
        #if DEBUG
        // Given
        AppInitializationService.testInjectedFailure = .cachePreloadFailed
        defer { AppInitializationService.testInjectedFailure = nil }

        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        // When
        let result = await manager.performStartup()

        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(manager.startupState.isFailed)
        XCTAssertLessThan(manager.progress, 1.0)
        XCTAssertNotNil(result.error)
        XCTAssertTrue(result.error?.localizedDescription.contains("缓存预加载失败") ?? false)
        #endif
    }
    @MainActor
    func testStartupFailure_InjectionSetsFailedState() async {
        #if DEBUG
        // Given
        AppInitializationService.testInjectedFailure = .cachePreloadFailed
        defer { AppInitializationService.testInjectedFailure = nil }
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        // When
        let result = await manager.performStartup()

        // Then
        XCTAssertFalse(result.success)
        XCTAssertTrue(manager.startupState.isFailed)
        XCTAssertLessThan(manager.progress, 1.0)
        XCTAssertNotNil(result.error)
        if let err = result.error as? AppInitializationError {
            XCTAssertEqual(err, .cachePreloadFailed)
        }
        #endif
    }
    @MainActor
    func testStartupSuccess_CompletesWithProgressOne() async {
        // Given
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        // When
        let result = await manager.performStartup()

        // Then
        XCTAssertTrue(result.success)
        XCTAssertEqual(manager.startupState, .completed)
        XCTAssertEqual(manager.currentStep?.id, "ui_preparation")
        XCTAssertEqual(manager.currentStep?.name, "界面准备")
        XCTAssertEqual(manager.progress, 1.0, accuracy: 0.0001)
        XCTAssertGreaterThan(result.duration, 0.0)
        XCTAssertGreaterThan(result.completedSteps, 0)
    }

    @MainActor
    func testReset_ClearsState() async {
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        _ = await manager.performStartup()
        manager.reset()

        XCTAssertEqual(manager.startupState, .notStarted)
        XCTAssertNil(manager.currentStep)
        XCTAssertEqual(manager.progress, 0.0)
    }

    @MainActor
    func testMinimumDisplayTimeHonoredInDebug() async {
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )

        let start = CFAbsoluteTimeGetCurrent()
        let result = await manager.performStartup()
        let duration = CFAbsoluteTimeGetCurrent() - start
        XCTAssertTrue(result.success)
        #if DEBUG
        XCTAssertGreaterThanOrEqual(duration, AppConfiguration.Lifecycle.Launch.minimumDisplayTime - 0.05)
        #endif
    }

    func testStartupStateEquatableHelpers() {
        XCTAssertTrue(StartupState.notStarted == .notStarted)
        XCTAssertTrue(StartupState.starting == .starting)
        XCTAssertTrue(StartupState.completed == .completed)
        XCTAssertTrue(StartupState.failed(AppInitializationError.cachePreloadFailed).isFailed)
        XCTAssertTrue(StartupState.completed.isCompleted)
    }

    func testStartupErrorDescription() {
        let configInvalid = StartupError.configurationInvalid(["x", "y"]).localizedDescription
        XCTAssertTrue(configInvalid.contains("配置验证失败"))

        let unknown = StartupError.unknownStep("abc").localizedDescription
        XCTAssertTrue(unknown.contains("未知的启动步骤"))

        let timeout = StartupError.timeout.localizedDescription
        XCTAssertTrue(timeout.contains("启动超时"))
    }
}
