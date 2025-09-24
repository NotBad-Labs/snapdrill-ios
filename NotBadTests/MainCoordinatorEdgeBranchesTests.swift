import XCTest
@testable import NotBad

@MainActor
final class MainCoordinatorEdgeBranchesTests: XCTestCase {
    func testTabSwitches_setSelectedTabCorrectly() {
        let sut = MainCoordinator()
        sut.start()
        sut.coordinate(to: .home)
        XCTAssertEqual(sut.selectedTab, 0)
        sut.coordinate(to: .library)
        XCTAssertEqual(sut.selectedTab, 1)
        sut.coordinate(to: .capture)
        XCTAssertEqual(sut.selectedTab, 2)
        sut.coordinate(to: .discovery)
        XCTAssertEqual(sut.selectedTab, 3)
        sut.coordinate(to: .profile)
        XCTAssertEqual(sut.selectedTab, 4)
    }

    func testGetTabCoordinator_validAndInvalidIndices() {
        let sut = MainCoordinator()
        XCTAssertNotNil(sut.getTabCoordinator(at: 0))
        XCTAssertNotNil(sut.getTabCoordinator(at: 1))
        XCTAssertNotNil(sut.getTabCoordinator(at: 2))
        XCTAssertNotNil(sut.getTabCoordinator(at: 3))
        XCTAssertNotNil(sut.getTabCoordinator(at: 4))
        XCTAssertNil(sut.getTabCoordinator(at: -1))
        XCTAssertNil(sut.getTabCoordinator(at: 99))
    }

    func testGetCurrentTabCoordinator_invalidSelectedTab_returnsNil() {
        let sut = MainCoordinator()
        sut.selectedTab = 99
        XCTAssertNil(sut.getCurrentTabCoordinator())
    }

    func testCoordinate_defaultBranch_withNoCurrentCoordinator_noCrash() {
        let sut = MainCoordinator()
        sut.selectedTab = 99 // invalid tab -> getCurrentTabCoordinator() returns nil
        sut.coordinate(to: .detail(module: "library", id: "abc"))
        // Should not crash and should keep selectedTab unchanged
        XCTAssertEqual(sut.selectedTab, 99)
    }
}
