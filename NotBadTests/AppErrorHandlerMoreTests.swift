import XCTest
@testable import NotBad

@MainActor
final class AppErrorHandlerMoreTests: XCTestCase {
    func test_present_info_doesNotSetCurrentError() {
        let handler = AppErrorHandler()
        handler.present(message: "just info", severity: .info)
        // info 级别只记录，不展示
        XCTAssertNil(handler.currentError)
    }

    func test_present_warning_setsAndWeCanClear() async {
        let handler = AppErrorHandler()
        handler.present(message: "warn", severity: .warning)
        // 警告会设置 currentError（带有自动清除定时器，但这里不等待）
        XCTAssertNotNil(handler.currentError)
        // 主动清理以避免等待 3s
        handler.clearError()
        XCTAssertNil(handler.currentError)
    }

    func test_handle_critical_setsCurrentError() {
        let handler = AppErrorHandler()
        // AppInitializationError 会被归类为 critical
        handler.handle(AppInitializationError.serviceInitializationFailed)
        XCTAssertNotNil(handler.currentError)
        XCTAssertEqual(handler.currentError?.severity, .critical)
    }
}
