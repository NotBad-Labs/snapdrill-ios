import XCTest
@testable import NotBad

@MainActor
final class CoordinatorDefaultBranchTests: XCTestCase {
    func test_HomeCoordinator_defaultBranch_noCrash() {
        let c = HomeCoordinator()
        c.start()
        // 传入与该协调器无关的路由，应该走 default 分支且不崩溃
        c.coordinate(to: .detail(module: "library", id: "x"))
        XCTAssertTrue(true)
    }

    func test_LibraryCoordinator_defaultBranch_noCrash() {
        let c = LibraryCoordinator()
        c.start()
        c.coordinate(to: .detail(module: "home", id: "x"))
        XCTAssertTrue(true)
    }

    func test_CaptureCoordinator_defaultBranch_noCrash() {
        let c = CaptureCoordinator()
        c.start()
        c.coordinate(to: .detail(module: "profile", id: "x"))
        XCTAssertTrue(true)
    }

    func test_ProfileCoordinator_defaultBranch_noCrash() {
        let c = ProfileCoordinator()
        c.start()
        c.coordinate(to: .detail(module: "capture", id: "x"))
        XCTAssertTrue(true)
    }
}
