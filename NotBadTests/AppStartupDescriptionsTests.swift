import XCTest
@testable import NotBad

final class AppStartupDescriptionsTests: XCTestCase {
    func test_StartupError_errorDescription_coversAllCases() {
        let e1: StartupError = .configurationInvalid(["A", "B"]) 
        let e2: StartupError = .unknownStep("xyz")
        let e3: StartupError = .timeout
        XCTAssertTrue((e1.errorDescription ?? "").contains("配置验证失败"))
        XCTAssertTrue((e2.errorDescription ?? "").contains("未知的启动步骤"))
        XCTAssertTrue((e3.errorDescription ?? "").contains("启动超时"))
    }

    func test_StartupResult_description_success_and_failure() {
        let ok = StartupResult(success: true, duration: 1.23, completedSteps: 7, error: nil)
        XCTAssertTrue(ok.description.contains("✅ 启动成功"))

        let fail = StartupResult(success: false, duration: 2.34, completedSteps: 3, error: StartupError.timeout)
        XCTAssertTrue(fail.description.contains("❌ 启动失败"))
    }
}
