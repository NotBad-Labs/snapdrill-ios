import XCTest
@testable import NotBad

final class AppStartupManagerTests: XCTestCase {
    @MainActor
    func testStartupCancellation() async {
        let service = AppInitializationService()
        let errorHandler = AppErrorHandler()
        let config = AppConfiguration.current
        let manager = AppStartupManager(
            initializationService: service,
            errorHandler: errorHandler,
            configuration: config
        )
        let task = Task { await manager.performStartup() }
        // Cancel almost immediately
        task.cancel()
        let result = await task.value
        XCTAssertFalse(result.success, "Startup should not succeed if cancelled")
        XCTAssertTrue(manager.startupState == .notStarted || manager.startupState.isFailed, "Startup state should reflect cancellation")
    }
}
